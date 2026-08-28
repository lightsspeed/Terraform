# ==============================================================================
# S3 BUCKET NOTIFICATIONS
# Sends event notifications to SNS when objects are created in the bucket.
# SNS can fan out to email, SQS, Lambda, or HTTP endpoints via subscriptions.
# ==============================================================================

# ------------------------------------------------------------------------------
# SNS TOPIC — receives the S3 event notifications
# ------------------------------------------------------------------------------
resource "aws_sns_topic" "bucket-notifications" {
  name              = "${var.bucket_name}-notifications"
  kms_master_key_id = aws_kms_key.bucket-kms-key.id # Encrypt SNS messages with same KMS key

  tags = {
    Name        = "${var.bucket_name}-notifications"
    Environment = var.tags.Environment
  }
}

# ------------------------------------------------------------------------------
# SNS TOPIC POLICY — grants S3 permission to publish to this topic
# Without this, S3 cannot send events to the SNS topic (access denied)
# ------------------------------------------------------------------------------
resource "aws_sns_topic_policy" "bucket-notification-policy" {
  arn = aws_sns_topic.bucket-notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3Publish"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.bucket-notifications.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.bucket.arn
          }
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# S3 BUCKET NOTIFICATION — triggers the SNS topic on object create events
# Events covered:
#   s3:ObjectCreated:* → fires for PUT, POST, COPY, CompleteMultipartUpload
#
# Commented-out alternatives for SQS and Lambda are shown below.
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_notification" "bucket-notification" {
  bucket = aws_s3_bucket.bucket.id

  # --- SNS Notification ---
  topic {
    id        = "notify-on-object-created"
    topic_arn = aws_sns_topic.bucket-notifications.arn
    events    = ["s3:ObjectCreated:*"]
    # Optional: filter to a specific prefix/suffix
    # filter_prefix = "uploads/"
    # filter_suffix = ".json"
  }

  # --- SQS Alternative (uncomment to use) ---
  # queue {
  #   id        = "notify-sqs-on-object-created"
  #   queue_arn = aws_sqs_queue.bucket-queue.arn
  #   events    = ["s3:ObjectCreated:*"]
  # }

  # --- Lambda Alternative (uncomment to use) ---
  # lambda_function {
  #   id                  = "notify-lambda-on-object-created"
  #   lambda_function_arn = aws_lambda_function.my-function.arn
  #   events              = ["s3:ObjectCreated:*"]
  # }

  depends_on = [aws_sns_topic_policy.bucket-notification-policy]
}

# ------------------------------------------------------------------------------
# OUTPUTS
# ------------------------------------------------------------------------------
output "sns_topic_arn" {
  value       = aws_sns_topic.bucket-notifications.arn
  description = "ARN of the SNS topic that receives S3 event notifications"
}
