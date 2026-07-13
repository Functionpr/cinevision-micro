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

  frontend_bucket_id                   = var.create_bucket ? aws_s3_bucket.frontend[0].id : var.existing_bucket_id
  frontend_bucket_arn                  = var.create_bucket ? aws_s3_bucket.frontend[0].arn : var.existing_bucket_arn
  frontend_bucket_regional_domain_name = var.create_bucket ? aws_s3_bucket.frontend[0].bucket_regional_domain_name : var.existing_bucket_regional_domain_name
  frontend_bucket_website_endpoint     = var.create_bucket ? aws_s3_bucket_website_configuration.frontend[0].website_endpoint : null
  frontend_bucket_website_domain       = var.create_bucket ? aws_s3_bucket_website_configuration.frontend[0].website_domain : null
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
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "frontend" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
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

data "aws_iam_policy_document" "frontend_bucket" {
  count = var.create_bucket ? 1 : 0

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${local.frontend_bucket_arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  count  = var.create_bucket ? 1 : 0
  bucket = local.frontend_bucket_id
  policy = data.aws_iam_policy_document.frontend_bucket[0].json

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

  depends_on = [
    aws_s3_bucket_public_access_block.frontend,
    aws_s3_bucket_ownership_controls.frontend
  ]
}
