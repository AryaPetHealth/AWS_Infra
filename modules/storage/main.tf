# --- S3: uploaded documents ---

resource "aws_s3_bucket" "documents" {
  bucket = var.documents_bucket_name
  tags   = { Name = var.documents_bucket_name }
}

resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "documents" {
  bucket = aws_s3_bucket.documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- SQS: decouples upload from OCR processing ---

resource "aws_sqs_queue" "processing_dlq" {
  name                      = "${var.project_name}-${var.environment}-processing-dlq"
  message_retention_seconds = 1209600 # 14 days
  tags                      = { Name = "${var.project_name}-${var.environment}-processing-dlq" }
}

resource "aws_sqs_queue" "processing" {
  name                       = "${var.project_name}-${var.environment}-processing"
  visibility_timeout_seconds = 120 # long enough for a Textract call
  tags                       = { Name = "${var.project_name}-${var.environment}-processing" }

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.processing_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue_policy" "processing" {
  queue_url = aws_sqs_queue.processing.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowS3SendMessage"
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.processing.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_s3_bucket.documents.arn }
      }
    }]
  })
}

resource "aws_s3_bucket_notification" "documents" {
  bucket = aws_s3_bucket.documents.id

  queue {
    queue_arn = aws_sqs_queue.processing.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sqs_queue_policy.processing]
}

# --- SNS: APNs platform application for push-on-complete ---
# The EB app registers each device token as a platform endpoint under this
# application and publishes directly to that endpoint ARN — no fan-out
# topic needed for single-recipient "job done" notifications.

resource "aws_sns_platform_application" "apns" {
  count = var.enable_apns ? 1 : 0

  name                = "${var.project_name}-${var.environment}-apns"
  platform            = var.apns_sandbox ? "APNS_SANDBOX" : "APNS"
  platform_credential = var.apns_signing_key
  platform_principal  = var.apns_signing_key_id

  apple_platform_team_id   = var.apns_team_id
  apple_platform_bundle_id = var.apns_bundle_id
}
