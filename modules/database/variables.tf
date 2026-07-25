variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "app_security_group_id" {
  description = "Security group ID of the EB app, granted inbound Postgres access"
  type        = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_allocated_storage" {
  type = number
}
