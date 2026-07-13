output "primary_instance_id" {
  value = aws_db_instance.primary.id
}

output "primary_endpoint" {
  value = aws_db_instance.primary.endpoint
}

output "primary_arn" {
  value = aws_db_instance.primary.arn
}

output "dr_replica_id" {
  value = try(aws_db_instance.dr_replica[0].id, null)
}

output "dr_replica_endpoint" {
  value = try(aws_db_instance.dr_replica[0].endpoint, null)
}
