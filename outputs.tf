output "cognito_user_pool_id" {
  value = module.cognito.user_pool_id
}

output "cognito_user_pool_client_id" {
  value = module.cognito.user_pool_client_id
}

output "cognito_hosted_ui_domain" {
  value = module.cognito.user_pool_domain
}

output "documents_bucket_name" {
  value = module.storage.documents_bucket_name
}

output "processing_queue_url" {
  value = module.storage.processing_queue_url
}

output "apns_platform_application_arn" {
  value = module.storage.apns_platform_application_arn
}

output "db_endpoint" {
  value = module.database.endpoint
}

output "db_secret_arn" {
  value = module.database.secret_arn
}

output "eb_environment_endpoint_url" {
  value = module.compute.environment_endpoint_url
}

output "github_actions_role_arn" {
  description = "Set this as the AWS_ROLE_ARN repo variable in GitHub Actions"
  value       = aws_iam_role.github_actions_terraform.arn
}
