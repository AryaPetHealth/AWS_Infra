variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "documents_bucket_name" {
  type = string
}

variable "apns_signing_key" {
  type      = string
  sensitive = true
}

variable "apns_signing_key_id" {
  type      = string
  sensitive = true
}

variable "apns_team_id" {
  type      = string
  sensitive = true
}

variable "apns_bundle_id" {
  type = string
}

variable "apns_sandbox" {
  type    = bool
  default = false
}
