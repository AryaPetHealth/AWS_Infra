variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "security_group_id" {
  description = "Security group ID to attach to the EB EC2 instance"
  type        = string
}

variable "eb_instance_type" {
  type = string
}

variable "eb_solution_stack_name" {
  type = string
}

variable "documents_bucket_arn" {
  type = string
}

variable "processing_queue_arn" {
  type = string
}

variable "db_secret_arn" {
  type = string
}

variable "environment_variables" {
  description = "Env vars exposed to the app via aws:elasticbeanstalk:application:environment"
  type        = map(string)
  default     = {}
}
