terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.dr]
    }
  }
}

locals {
  common_tags = merge(var.tags, {
    Project   = var.project_name
    ManagedBy = "Terraform"
  })

  use_custom_certificate = try(trim(var.acm_certificate_arn, " ") != "", false)

  frontend_bucket_id                   = var.create_bucket ? aws_s3_bucket.frontend[0].id : var.existing_bucket_id
  frontend_bucket_arn                  = var.create_bucket ? aws_s3_bucket.frontend[0].arn : var.existing_bucket_arn
  frontend_bucket_regional_domain_name = var.create_bucket ? aws_s3_bucket.frontend[0].bucket_regional_domain_name : var.existing_bucket_regional_domain_name
}

resource "aws_s3_bucket" "frontend" {
  count  = var.create_bucket ? 1 : 0
  bucket = var.frontend_bucket_name
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "frontend" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  count                   = var.create_bucket ? 1 : 0
  bucket                  = aws_s3_bucket.frontend[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "logs" {
  count  = var.create_logs_bucket ? 1 : 0
  bucket = var.logs_bucket_name
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "logs" {
  count  = var.create_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count                   = var.create_logs_bucket ? 1 : 0
  bucket                  = aws_s3_bucket.logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "frontend_dr" {
  provider = aws.dr
  count    = var.enable_replication ? 1 : 0

  bucket = var.dr_frontend_bucket_name
  tags   = merge(local.common_tags, { Role = "dr" })
}

resource "aws_s3_bucket_versioning" "frontend_dr" {
  provider = aws.dr
  count    = var.enable_replication ? 1 : 0
  bucket   = aws_s3_bucket.frontend_dr[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_dr" {
  provider = aws.dr
  count    = var.enable_replication ? 1 : 0

  bucket                  = aws_s3_bucket.frontend_dr[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "replication" {
  count = var.enable_replication ? 1 : 0
  name  = "${var.project_name}-${var.environment}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "replication" {
  count = var.enable_replication ? 1 : 0
  name  = "${var.project_name}-${var.environment}-s3-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = [local.frontend_bucket_arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = ["${local.frontend_bucket_arn}/*"]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ]
        Resource = ["${aws_s3_bucket.frontend_dr[0].arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication" {
  count      = var.enable_replication ? 1 : 0
  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}

resource "aws_s3_bucket_replication_configuration" "frontend" {
  count  = var.enable_replication ? 1 : 0
  bucket = local.frontend_bucket_id
  role   = aws_iam_role.replication[0].arn

  rule {
    id     = "frontend-to-dr"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.frontend_dr[0].arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.frontend,
    aws_s3_bucket_versioning.frontend_dr
  ]
}

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "${var.project_name}-${var.environment}-frontend-oai"
}

data "aws_iam_policy_document" "frontend_bucket" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${local.frontend_bucket_arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.this.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = local.frontend_bucket_id
  policy = data.aws_iam_policy_document.frontend_bucket.json
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = var.price_class
  aliases             = var.aliases
  web_acl_id          = var.web_acl_arn

  origin {
    domain_name = local.frontend_bucket_regional_domain_name
    origin_id   = "frontend-s3-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "frontend-s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = !local.use_custom_certificate
    acm_certificate_arn            = local.use_custom_certificate ? var.acm_certificate_arn : null
    ssl_support_method             = local.use_custom_certificate ? "sni-only" : null
    minimum_protocol_version       = local.use_custom_certificate ? "TLSv1.2_2021" : null
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  lifecycle {
    precondition {
      condition = var.create_bucket || (
        try(trim(var.existing_bucket_id, " ") != "", false) &&
        try(trim(var.existing_bucket_arn, " ") != "", false) &&
        try(trim(var.existing_bucket_regional_domain_name, " ") != "", false)
      )
      error_message = "When create_bucket is false, existing_bucket_id, existing_bucket_arn, and existing_bucket_regional_domain_name must all be provided."
    }
  }

  tags = local.common_tags
}
