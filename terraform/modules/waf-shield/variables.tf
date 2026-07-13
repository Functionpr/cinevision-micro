variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "scope" {
  type    = string
  default = "CLOUDFRONT"
  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.scope)
    error_message = "scope must be CLOUDFRONT or REGIONAL."
  }
}

variable "enable_waf" {
  type    = bool
  default = true
}

variable "enable_shield_advanced" {
  type    = bool
  default = false
}

variable "waf_rate_limit" {
  type    = number
  default = 2000
}

variable "cloudfront_resource_arns" {
  type    = list(string)
  default = []
}

variable "log_destination_configs" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
