output "primary_cluster_endpoint" {
  value = aws_docdb_cluster.primary.endpoint
}

output "primary_reader_endpoint" {
  value = aws_docdb_cluster.primary.reader_endpoint
}

output "global_cluster_id" {
  value = try(aws_docdb_global_cluster.this[0].id, null)
}

output "dr_cluster_endpoint" {
  value = try(aws_docdb_cluster.dr[0].endpoint, null)
}
