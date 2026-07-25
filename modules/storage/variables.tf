variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "documents_bucket_name" {
  type = string
}

variable "enable_apns" {
  description = "Set true once a real APNs token-signing key is supplied"
  type        = bool
  default     = false
}

variable "apns_signing_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "apns_signing_key_id" {
  type      = string
  sensitive = true
  default   = ""
}

variable "apns_team_id" {
  type      = string
  sensitive = true
  default   = ""
}

variable "apns_bundle_id" {
  type    = string
  default = ""
}

variable "apns_sandbox" {
  type    = bool
  default = false
}
