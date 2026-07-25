variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "enable_apple_signin" {
  description = "Set true once real Sign in with Apple credentials are supplied"
  type        = bool
  default     = false
}

variable "apple_services_id" {
  type      = string
  sensitive = true
  default   = ""
}

variable "apple_team_id" {
  type      = string
  sensitive = true
  default   = ""
}

variable "apple_key_id" {
  type      = string
  sensitive = true
  default   = ""
}

variable "apple_private_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "callback_urls" {
  type = list(string)
}

variable "logout_urls" {
  type = list(string)
}
