# ==============================================================================
# PRIMARY S3 BUCKET — Core resource and all directly attached configurations
#
# Resource dependency order (Terraform resolves this via implicit references):
#   aws_s3_bucket
#     └─► aws_s3_bucket_public_access_block
#     └─► aws_s3_bucket_versioning
#           └─► aws_s3_bucket_object_lock_configuration
#           └─► aws_s3_bucket_lifecycle_configuration
#     └─► aws_kms_key
#           └─► aws_s3_bucket_server_side_encryption_configuration
#     └─► aws_s3_bucket_policy  (also depends on public_access_block)
#     └─► aws_s3_bucket_analytics_configuration
# ==============================================================================

# ------------------------------------------------------------------------------
# CORE BUCKET
# object_lock_enabled MUST be set at bucket creation time — it cannot be
# enabled after the bucket exists. Enabling it here activates WORM support
# and is a prerequisite for aws_s3_bucket_object_lock_configuration below.
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name

  # Object Lock (WORM) must be activated at bucket creation — not configurable later
  object_lock_enabled = true

  tags = {
    Name        = var.bucket_name
    Environment = var.tags.Environment
  }
}

# ------------------------------------------------------------------------------
# OUTPUT — exposes the bucket ID (== bucket name) for use by other modules
# ------------------------------------------------------------------------------
output "bucket_name" {
  value       = aws_s3_bucket.bucket.id
  description = "Name of the S3 bucket"
}

# ------------------------------------------------------------------------------
# PUBLIC ACCESS BLOCK
# Applies four independent S3-level guardrails:
#   block_public_acls       — rejects PUT requests that grant public ACL access
#   block_public_policy     — rejects bucket policies that allow public access
#   ignore_public_acls      — ignores existing public ACLs at read time
#   restrict_public_buckets — restricts cross-account access for public buckets
# All four must be true for a fully locked-down bucket.
# NOTE: must be applied BEFORE the bucket policy (see depends_on on bucket-policy).
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "bucket-public-access-block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# VERSIONING
# Keeps every version of every object, enabling recovery from accidental
# deletes or overwrites. Also a hard requirement for:
#   - Object Lock / WORM retention (object_lock_configuration below)
#   - Cross-Region Replication (replication.tf)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "bucket-versioning" {
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Enabled" # Valid values: Enabled | Suspended
  }
}

# ------------------------------------------------------------------------------
# OBJECT LOCK CONFIGURATION (WORM — Write Once Read Many)
# Prevents objects from being deleted or overwritten for a defined retention period.
# GOVERNANCE mode: protects objects from most users, but privileged IAM users
#   with s3:BypassGovernanceRetention can still override the lock.
# COMPLIANCE mode (stricter): no one — not even root — can delete before expiry.
# days = 1 is set here for lab/dev purposes; increase for production use.
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_object_lock_configuration" "bucket-object-lock-configuration" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    default_retention {
      mode = "GOVERNANCE" # Use "COMPLIANCE" for stricter, irrevocable protection
      days = 1            # Minimum retention period for every newly uploaded object
    }
  }
}

# ------------------------------------------------------------------------------
# KMS CUSTOMER MANAGED KEY (CMK)
# Creates a dedicated KMS key for encrypting all bucket objects (SSE-KMS).
# Using a CMK (vs. AWS-managed key) gives you:
#   - Full key rotation control
#   - Ability to audit usage via CloudTrail
#   - Key policy customisation (restrict who can decrypt)
# deletion_window_in_days: KMS holds the key for this many days after deletion
#   before permanently destroying it — allows recovery if deleted by mistake.
# ------------------------------------------------------------------------------
resource "aws_kms_key" "bucket-kms-key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10 # Grace period (7-30 days) before key is destroyed
}

# ------------------------------------------------------------------------------
# SERVER-SIDE ENCRYPTION (SSE-KMS)
# Configures default encryption for all objects stored in the bucket.
# sse_algorithm = "aws:kms" — uses KMS for envelope encryption.
# kms_master_key_id — references the CMK created above (not the AWS-managed key).
# Objects uploaded without an explicit encryption header will be encrypted
# automatically using this default rule.
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket-server-side-encryption-configuration" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket-kms-key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# ------------------------------------------------------------------------------
# BUCKET POLICY — Enforce HTTPS (TLS) only access
# Uses a Deny statement to block ANY S3 action performed over plain HTTP.
# aws:SecureTransport = false means the request did NOT use TLS/HTTPS.
# Applies to all principals (*) including authenticated IAM users.
# depends_on ensures the public access block is in place before the policy,
# because some policy combinations are rejected without the block applied first.
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "bucket-tls-policy" {
  statement {
    sid     = "DenyNonTLS"
    effect  = "Deny"
    actions = ["s3:*"] # Deny ALL S3 operations when not using HTTPS

    # Applies to both the bucket itself and all objects inside it
    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*",
    ]

    # Wildcard principal — applies to every caller (IAM users, roles, services)
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    # Condition: only trigger the Deny when request is NOT using TLS
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket-policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket-tls-policy.json

  # Public access block must exist before attaching a bucket policy that
  # references public principals — prevents intermittent apply errors
  depends_on = [aws_s3_bucket_public_access_block.bucket-public-access-block]
}

# ------------------------------------------------------------------------------
# LIFECYCLE CONFIGURATION — Automatic storage tiering and cleanup
# Reduces costs by automatically moving objects to cheaper storage classes
# as they age, and cleans up stale data without manual intervention.
#
# Rule: "tiering-and-cleanup" applies to ALL objects (empty filter = match all)
#   30 days  → STANDARD_IA   (Infrequent Access, ~40% cheaper than Standard)
#   90 days  → GLACIER        (Archive, ~80% cheaper than Standard)
#   365 days → expire non-current versions (old versions from versioning)
#   7 days   → abort failed/incomplete multipart uploads (avoids orphan charges)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "bucket-lifecycle" {
  bucket = aws_s3_bucket.bucket.id

  # Versioning must be enabled first — noncurrent_version_expiration requires it
  depends_on = [aws_s3_bucket_versioning.bucket-versioning]

  rule {
    id     = "tiering-and-cleanup"
    status = "Enabled" # Set to "Disabled" to pause without deleting the rule

    # Empty filter block = apply this rule to ALL objects in the bucket.
    # To target a subset, use: filter { prefix = "logs/" } or filter { tags = {...} }
    filter {}

    # Move objects to Standard-IA after 30 days of no access
    # Best for objects accessed less than once a month
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Move objects to Glacier after 90 days — retrieval takes minutes to hours
    # Best for long-term archival where immediate access is not needed
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Permanently delete old (non-current) object versions after 1 year
    # Prevents unbounded versioning storage growth over time
    noncurrent_version_expiration {
      noncurrent_days = 365
    }

    # Clean up orphaned multipart upload parts older than 7 days
    # Failed uploads leave partial data that incurs storage charges if not removed
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ------------------------------------------------------------------------------
# STORAGE CLASS ANALYTICS — S3 Storage Class Analysis
# Monitors object access patterns across the entire bucket and generates
# recommendations for optimal lifecycle transition points (e.g., suggests
# when to transition to STANDARD_IA based on real access frequency).
# Results appear in the S3 console → Analytics tab after 24-48 hours.
# Use this data to fine-tune the transition days in the lifecycle rule above.
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_analytics_configuration" "bucket-analytics" {
  bucket = aws_s3_bucket.bucket.id
  name   = "EntireBucket" # Logical name for this analytics config; shown in console
}
