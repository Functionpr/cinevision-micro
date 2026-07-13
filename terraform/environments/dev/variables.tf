variable "project_name" {
  type    = string
  default = "cinevision"
}
variable "aws_profile" {
  type    = string
  default = null
}
variable "primary_region" {
  type    = string
  default = "us-east-1"
}
variable "dr_region" {
  type    = string
  default = "us-west-2"
}
variable "cidr_block" {
  type    = string
  default = "10.10.0.0/16"
}
variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]
}
variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24"]
}
variable "database_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.20.0/24", "10.10.21.0/24", "10.10.22.0/24"]
}
variable "frontend_bucket_name" {
  type    = string
  default = "dev-cinevision-dev-frontend"
  validation {
    condition     = !strcontains(var.frontend_bucket_name, "BUCKET_NAME")
    error_message = "frontend_bucket_name still  contains BUCKET_NAME placeholder."
  }
}
variable "logs_bucket_name" {
  type    = string
  default = "dev-cinevision-dev-logs"
  validation {
    condition     = !strcontains(var.logs_bucket_name, "BUCKET_NAME")
    error_message = "logs_bucket_name still contains BUCKET_NAME placeholder."
  }
}
variable "movie_posters_bucket_name" {
  type    = string
  default = "dev-cinevision-dev-movie-posters"
  validation {
    condition     = !strcontains(var.movie_posters_bucket_name, "BUCKET_NAME")
    error_message = "movie_posters_bucket_name  still contains BUCKET_NAME placeholder."
  }
}
variable "email_archives_bucket_name" {
  type    = string
  default = "dev-cinevision-dev-email-archives"
  validation {
    condition     = !strcontains(var.email_archives_bucket_name, "BUCKET_NAME")
    error_message = "email_archives_bucket_name still contains BUCKET_NAME placeholder."
  }
}
variable "frontend_aliases" {
  type    = list(string)
  default = ["dev.cinevisionca.link"]
  validation {
    condition     = alltrue([for a in var.frontend_aliases : !strcontains(a, "DOMAIN_NAME")])
    error_message = "frontend_aliases contains  DOMAIN_NAME placeholder."
  }
}
variable "acm_certificate_arn" {
  type    = string
  default = ""
  validation {
    condition     = !strcontains(var.acm_certificate_arn, "ACCOUNT_ID") && !strcontains(var.acm_certificate_arn, "CERTIFICATE_ID")
    error_message = "acm_certificate_arn still contains  ACCOUNT_ID/CERTIFICATE_ID placeholder."
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
variable "node_groups" {
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = number
    capacity_type  = string
  }))
  default = {
    general = {
      instance_types = ["t3.large"]
      desired_size   = 3
      min_size       = 2
      max_size       = 4
      disk_size      = 50
      capacity_type  = "ON_DEMAND"
    }
  }
}
variable "rds_instance_class" {
  type    = string
  default = "db.t4g.medium"
}
variable "db_name" {
  type    = string
  default = "cinevision"
}
variable "db_username" {
  type    = string
  default = "cinevision_admin"
}
variable "docdb_master_username" {
  type    = string
  default = "cinevision_docdb_admin"
}
variable "database_credentials_secret_name" {
  type    = string
  default = "/cinevision/dev/database-credentials"
}
variable "application_secrets_secret_name" {
  type    = string
  default = "/cinevision/dev/application-secrets"
}
variable "redis_node_type" {
  type    = string
  default = "cache.t4g.small"
}
variable "msk_broker_count" {
  type    = number
  default = 3
}
variable "msk_broker_instance_type" {
  type    = string
  default = "kafka.t3.small"
}
variable "tags" {
  type = map(string)
  default = {
    Owner = "platform-team1"
  }
}
