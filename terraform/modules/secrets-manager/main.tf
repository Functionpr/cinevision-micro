locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    DataClass   = "SecretMetadata"
  })
}

resource "aws_secretsmanager_secret" "database_credentials" {
  count                   = var.create_database_credentials_secret ? 1 : 0
  name                    = var.database_credentials_secret_name
  description             = "CineVision ${var.environment} database credentials (JSON payload)"
  recovery_window_in_days = var.recovery_window_in_days
  kms_key_id              = var.kms_key_id
  tags                    = local.common_tags
}

resource "aws_secretsmanager_secret" "application_secrets" {
  count                   = var.create_application_secrets_secret ? 1 : 0
  name                    = var.application_secrets_secret_name
  description             = "CineVision ${var.environment} runtime application secrets (JSON payload)"
  recovery_window_in_days = var.recovery_window_in_days
  kms_key_id              = var.kms_key_id
  tags                    = local.common_tags
}
