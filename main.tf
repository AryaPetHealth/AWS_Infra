data "aws_vpc" "default" {
  default = true
}

# Shared by compute (attached to the EC2 instance) and database (source of
# the RDS ingress rule) — lives at root so neither module depends on the
# other's output, which would create a module cycle.
resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app"
  description = "EB app instance"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "cognito" {
  source = "./modules/cognito"

  project_name = var.project_name
  environment  = var.environment

  enable_apple_signin = var.enable_apple_signin
  apple_services_id    = var.apple_services_id
  apple_team_id        = var.apple_team_id
  apple_key_id         = var.apple_key_id
  apple_private_key    = var.apple_private_key

  callback_urls = var.cognito_callback_urls
  logout_urls   = var.cognito_logout_urls
}

module "storage" {
  source = "./modules/storage"

  project_name          = var.project_name
  environment           = var.environment
  documents_bucket_name = var.documents_bucket_name

  enable_apns         = var.enable_apns
  apns_signing_key    = var.apns_signing_key
  apns_signing_key_id = var.apns_signing_key_id
  apns_team_id        = var.apns_team_id
  apns_bundle_id      = var.apns_bundle_id
  apns_sandbox        = var.apns_sandbox
}

module "database" {
  source = "./modules/database"

  project_name = var.project_name
  environment  = var.environment

  app_security_group_id = aws_security_group.app.id

  db_name              = var.db_name
  db_username          = var.db_username
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
}

module "compute" {
  source = "./modules/compute"

  project_name = var.project_name
  environment  = var.environment

  security_group_id = aws_security_group.app.id

  eb_instance_type       = var.eb_instance_type
  eb_solution_stack_name = var.eb_solution_stack_name

  documents_bucket_arn = module.storage.documents_bucket_arn
  processing_queue_arn = module.storage.processing_queue_arn
  db_secret_arn        = module.database.secret_arn

  environment_variables = {
    AWS_REGION                = var.aws_region
    S3_DOCUMENTS_BUCKET       = module.storage.documents_bucket_name
    SQS_PROCESSING_QUEUE_URL  = module.storage.processing_queue_url
    SNS_APNS_PLATFORM_APP_ARN = module.storage.apns_platform_application_arn
    DB_SECRET_ARN             = module.database.secret_arn
    COGNITO_USER_POOL_ID      = module.cognito.user_pool_id
    COGNITO_APP_CLIENT_ID     = module.cognito.user_pool_client_id
  }
}
