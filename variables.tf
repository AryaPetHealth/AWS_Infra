variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Short name used to prefix/tag resources"
  type        = string
  default     = "arya"
}

variable "environment" {
  description = "Deployment environment name (e.g. dev, prod)"
  type        = string
  default     = "prod"
}

variable "github_repo" {
  description = "GitHub repo (owner/name) allowed to assume the CI IAM role via OIDC"
  type        = string
  default     = "AryaPetHealth/AWS_Infra"
}

# --- Cognito / Sign in with Apple ---
# Deferred until real Apple credentials exist. Cognito still stands up with
# plain username/password auth; flip enable_apple_signin to true and fill
# in the rest once you have them.

variable "enable_apple_signin" {
  description = "Set true once real Sign in with Apple credentials are supplied below"
  type        = bool
  default     = false
}

variable "apple_services_id" {
  description = "Apple 'Sign in with Apple' Services ID, used as the Cognito identity provider client_id"
  type        = string
  sensitive   = true
  default     = ""
}

variable "apple_team_id" {
  description = "Apple Developer Team ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "apple_key_id" {
  description = "Key ID for the Sign in with Apple private key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "apple_private_key" {
  description = "Contents of the Sign in with Apple .p8 private key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cognito_callback_urls" {
  description = "Allowed OAuth callback URLs for the Cognito app client"
  type        = list(string)
  default     = ["arya://callback"]
}

variable "cognito_logout_urls" {
  description = "Allowed OAuth logout URLs for the Cognito app client"
  type        = list(string)
  default     = ["arya://logout"]
}

# --- SNS / APNs push ---
# Deferred until a real APNs signing key exists; flip enable_apns to true
# once you have one.

variable "enable_apns" {
  description = "Set true once a real APNs token-signing key is supplied below"
  type        = bool
  default     = false
}

variable "apns_signing_key" {
  description = "Contents of the APNs .p8 token-signing key (token-based auth)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "apns_signing_key_id" {
  description = "Key ID for the APNs token-signing key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "apns_team_id" {
  description = "Apple Developer Team ID (APNs)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "apns_bundle_id" {
  description = "iOS app bundle identifier registered for push notifications"
  type        = string
  default     = ""
}

variable "apns_sandbox" {
  description = "Whether to use the APNs sandbox environment instead of production"
  type        = bool
  default     = false
}

# --- RDS ---

variable "db_name" {
  description = "Postgres database name"
  type        = string
  default     = "arya"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "arya_admin"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

# --- Elastic Beanstalk ---

variable "eb_instance_type" {
  description = "EC2 instance type for the Elastic Beanstalk environment"
  type        = string
  default     = "t3.micro"
}

variable "eb_solution_stack_name" {
  description = "Elastic Beanstalk solution stack (Docker platform)"
  type        = string
  default     = "64bit Amazon Linux 2023 v4.3.4 running Docker"
}

# --- S3 ---

variable "documents_bucket_name" {
  description = "Globally-unique S3 bucket name for uploaded pet health documents"
  type        = string
}
