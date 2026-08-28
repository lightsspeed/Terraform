# ==============================================================================
# CROSS-REGION REPLICATION (CRR)
# Replicates all objects from the primary bucket (us-east-1) to a replica
# bucket in a different AWS region (us-west-2 by default) for DR purposes.
# ==============================================================================

# ------------------------------------------------------------------------------
# REPLICA BUCKET — destination in a separate region
# Uses a separate provider alias so Terraform can target us-west-2
# ------------------------------------------------------------------------------
provider "aws" {
  alias  = "replica"
  region = var.replication_region
}

resource "aws_s3_bucket" "replica" {
  provider = aws.replica
  bucket   = var.replica_bucket_name != "" ? var.replica_bucket_name : "${var.bucket_name}-replica"

  tags = {
    Name        = "${var.bucket_name}-replica"
    Environment = var.tags.Environment
    Purpose     = "CRR Destination"
  }
}

# Versioning must be ENABLED on both source and destination for CRR to work
resource "aws_s3_bucket_versioning" "replica-versioning" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access on replica bucket as well
resource "aws_s3_bucket_public_access_block" "replica-public-access-block" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# IAM ROLE — allows S3 to assume this role to perform replication
# Trust policy grants s3.amazonaws.com permission to call sts:AssumeRole
# ------------------------------------------------------------------------------
resource "aws_iam_role" "replication-role" {
  name = "${var.bucket_name}-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.bucket_name}-replication-role"
    Environment = var.tags.Environment
  }
}

# ------------------------------------------------------------------------------
# IAM POLICY — permissions the replication role needs:
#   - Read from the SOURCE bucket (list, get objects, get replication config)
#   - Write to the REPLICA bucket (replicate objects, delete markers, tags)
# ------------------------------------------------------------------------------
resource "aws_iam_policy" "replication-policy" {
  name        = "${var.bucket_name}-replication-policy"
  description = "Allows S3 to replicate objects from source to replica bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SourceBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
        ]
        Resource = [aws_s3_bucket.bucket.arn]
      },
      {
        Sid    = "SourceObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
        ]
        Resource = ["${aws_s3_bucket.bucket.arn}/*"]
      },
      {
        Sid    = "ReplicaDestinationAccess"
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
        ]
        Resource = ["${aws_s3_bucket.replica.arn}/*"]
      }
    ]
  })
}

# Attach the replication policy to the replication role
resource "aws_iam_role_policy_attachment" "replication-policy-attachment" {
  role       = aws_iam_role.replication-role.name
  policy_arn = aws_iam_policy.replication-policy.arn
}

# ------------------------------------------------------------------------------
# REPLICATION CONFIGURATION — defines what/where/how to replicate
# Applied on the SOURCE bucket; uses the IAM role above for permissions
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_replication_configuration" "bucket-replication" {
  bucket = aws_s3_bucket.bucket.id
  role   = aws_iam_role.replication-role.arn

  # Versioning must be enabled on the source before replication config is applied
  depends_on = [aws_s3_bucket_versioning.bucket-versioning]

  rule {
    id     = "replicate-all-objects"
    status = "Enabled"

    # Replicate ALL objects (no prefix/tag filter)
    filter {}

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD_IA" # Save cost on replica — infrequent access
    }

    # Also replicate delete markers so deletions are mirrored
    delete_marker_replication {
      status = "Enabled"
    }
  }
}

# ------------------------------------------------------------------------------
# OUTPUTS
# ------------------------------------------------------------------------------
output "replica_bucket_name" {
  value       = aws_s3_bucket.replica.id
  description = "Name of the CRR replica S3 bucket"
}

output "replication_role_arn" {
  value       = aws_iam_role.replication-role.arn
  description = "ARN of the IAM role used for S3 replication"
}
