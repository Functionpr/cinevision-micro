output "frontend_bucket_name" {
  value = var.frontend_bucket_name
}

output "logs_bucket_name" {
  value = var.logs_bucket_name
}

output "dr_frontend_bucket_name" {
  value = try(aws_s3_bucket.frontend_dr[0].bucket, null)
}

output "frontend_bucket_regional_domain_name" {
  value = local.frontend_bucket_regional_domain_name
}

output "frontend_website_endpoint" {
  value = local.frontend_bucket_website_endpoint
}

output "frontend_website_domain" {
  value = local.frontend_bucket_website_domain
}
