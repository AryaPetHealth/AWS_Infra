output "documents_bucket_name" {
  value = aws_s3_bucket.documents.id
}

output "documents_bucket_arn" {
  value = aws_s3_bucket.documents.arn
}

output "processing_queue_url" {
  value = aws_sqs_queue.processing.id
}

output "processing_queue_arn" {
  value = aws_sqs_queue.processing.arn
}

output "processing_dlq_arn" {
  value = aws_sqs_queue.processing_dlq.arn
}

output "apns_platform_application_arn" {
  value = var.enable_apns ? aws_sns_platform_application.apns[0].arn : ""
}
