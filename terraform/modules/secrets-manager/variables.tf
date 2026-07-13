variable "project_name" {
  description = "CineVision project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "database_credentials_secret_name" {
  description = "Secrets Manager name for database credentials JSON"
  type        = string
}

variable "application_secrets_secret_name" {
  description = "Secrets Manager name for runtime app secrets JSON"
  type        = string
}

variable "create_database_credentials_secret" {
  description = "Create the database credentials secret metadata container"
  type        = bool
  default     = true
}

variable "create_application_secrets_secret" {
  description = "Create the app secrets metadata container"
  type        = bool
  default     = true
}

variable "recovery_window_in_days" {
  description = "Secret recovery window before permanent deletion"
  type        = number
  default     = 30
}

variable "kms_key_id" {
  description = "Optional KMS key ARN for secret encryption"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to created secrets"
  type        = map(string)
  default     = {}
}
