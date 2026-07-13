output "dr_eks_cluster_name" {
  value = module.eks.cluster_name
}

output "dr_frontend_bucket_name" {
  value = data.terraform_remote_state.prod.outputs.dr_frontend_bucket_name
}

output "dr_postgres_replica_endpoint" {
  value = data.terraform_remote_state.prod.outputs.dr_postgres_replica_endpoint
}

output "dr_documentdb_endpoint" {
  value = data.terraform_remote_state.prod.outputs.dr_documentdb_endpoint
}

output "dr_redis_endpoint" {
  value = module.redis.primary_endpoint_address
}

output "dr_eks_managed_cluster_security_group_id" {
  description = "EKS-managed primary cluster security group used by prod-dr managed node group network interfaces."
  value       = module.eks.cluster_primary_security_group_id
}

output "dr_msk_bootstrap_brokers_tls" {
  value = module.msk.bootstrap_brokers_tls
}
