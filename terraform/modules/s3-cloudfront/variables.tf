variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "frontend_bucket_name" {
  type = string
}

variable "logs_bucket_name" {
  type = string
}

variable "dr_frontend_bucket_name" {
  type    = string
  default = null
}

variable "enable_replication" {
  type    = bool
  default = false
}

variable "aliases" {
  type    = list(string)
  default = []
}

variable "acm_certificate_arn" {
  type    = string
  default = null
}

variable "price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "web_acl_arn" {
  type    = string
  default = null
}

variable "create_bucket" {
  type    = bool
  default = true
}

variable "create_logs_bucket" {
  type    = bool
  default = true
}

variable "existing_bucket_id" {
  type    = string
  default = null
}

variable "existing_bucket_arn" {
  type    = string
  default = null
}

variable "existing_bucket_regional_domain_name" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
