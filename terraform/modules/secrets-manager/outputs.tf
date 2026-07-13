output "database_credentials_secret_name" {
  value = try(aws_secretsmanager_secret.database_credentials[0].name, var.database_credentials_secret_name)
}

output "database_credentials_secret_arn" {
  value = try(aws_secretsmanager_secret.database_credentials[0].arn, null)
}

output "application_secrets_secret_name" {
  value = try(aws_secretsmanager_secret.application_secrets[0].name, var.application_secrets_secret_name)
}

output "application_secrets_secret_arn" {
  value = try(aws_secretsmanager_secret.application_secrets[0].arn, null)
}
