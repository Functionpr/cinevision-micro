output "vpc_id" {
  value = module.vpc.vpc_id
}

output "frontend_bucket_name" {
  value = module.s3_cloudfront.frontend_bucket_name
}

output "cloudfront_domain_name" {
  value = module.s3_cloudfront.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  value = module.s3_cloudfront.cloudfront_distribution_id
}

output "movie_posters_cloudfront_distribution_id" {
  value = module.movie_posters_cloudfront.cloudfront_distribution_id
}

output "email_archives_cloudfront_distribution_id" {
  value = module.email_archives_cloudfront.cloudfront_distribution_id
}

output "waf_web_acl_arn" {
  value = module.waf.web_acl_arn
}

output "shield_protection_ids" {
  value = module.shield.shield_protection_ids
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "postgres_endpoint" {
  value = module.rds.primary_endpoint
}

output "documentdb_endpoint" {
  value = module.documentdb.primary_cluster_endpoint
}

output "redis_endpoint" {
  value = module.redis.primary_endpoint_address
}

output "msk_bootstrap_brokers_tls" {
  value = module.msk.bootstrap_brokers_tls
}

output "database_credentials_secret_name" {
  value = var.database_credentials_secret_name
}

output "application_secrets_secret_name" {
  value = data.aws_secretsmanager_secret.application_secrets.name
}

output "application_secrets_secret_arn" {
  value = data.aws_secretsmanager_secret.application_secrets.arn
}

output "eks_managed_cluster_security_group_id" {
  description = "EKS-managed primary cluster security group used by managed node group network interfaces."
  value       = module.eks.cluster_primary_security_group_id
}

output "eks_cluster_security_group_id" {
  value = module.vpc.eks_cluster_security_group_id
}

output "app_nodes_security_group_id" {
  value = module.vpc.app_nodes_security_group_id
}

output "rds_security_group_id" {
  value = module.vpc.rds_security_group_id
}

output "documentdb_security_group_id" {
  value = module.vpc.documentdb_security_group_id
}

output "redis_security_group_id" {
  value = module.vpc.redis_security_group_id
}

output "msk_security_group_id" {
  value = module.vpc.msk_security_group_id
}
