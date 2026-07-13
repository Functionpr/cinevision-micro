output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

output "database_subnet_ids" {
  value = [for subnet in aws_subnet.database : subnet.id]
}

output "eks_cluster_security_group_id" {
  value = aws_security_group.eks_cluster.id
}

output "app_nodes_security_group_id" {
  value = aws_security_group.app_nodes.id
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}

output "documentdb_security_group_id" {
  value = aws_security_group.documentdb.id
}

output "redis_security_group_id" {
  value = aws_security_group.redis.id
}

output "msk_security_group_id" {
  value = aws_security_group.msk.id
}
