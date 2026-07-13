terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.45"
    }
  }
}

provider "aws" {
  # profile = var.aws_profile
  region = var.primary_region
}

provider "aws" {
  alias = "dr"
  # profile = var.aws_profile
  region = var.dr_region
}

locals {
  environment = "dev"
  tags = merge(var.tags, {
    Environment = local.environment
    CostCenter  = "engineering"
  })
}

module "waf" {
  source = "../../modules/waf-shield"

  project_name   = var.project_name
  environment    = local.environment
  enable_waf     = var.enable_waf
  waf_rate_limit = var.waf_rate_limit
  tags           = local.tags
}

data "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id = var.database_credentials_secret_name
}

data "aws_secretsmanager_secret" "application_secrets" {
  name = var.application_secrets_secret_name
}

locals {
  database_credentials = jsondecode(data.aws_secretsmanager_secret_version.database_credentials.secret_string)
}

module "vpc" {
  source = "../../modules/vpc"

  project_name          = var.project_name
  environment           = local.environment
  cidr_block            = var.cidr_block
  azs                   = var.azs
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  single_nat_gateway    = true
  enable_nat_gateway    = true
  tags                  = local.tags
}

module "s3_cloudfront" {
  source = "../../modules/s3-cloudfront"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  project_name         = var.project_name
  environment          = local.environment
  frontend_bucket_name = var.frontend_bucket_name
  logs_bucket_name     = var.logs_bucket_name
  aliases              = var.frontend_aliases
  acm_certificate_arn  = var.acm_certificate_arn
  web_acl_arn          = module.waf.web_acl_arn
  enable_replication   = false
  tags                 = local.tags
}

module "movie_posters_s3" {
  source = "../../modules/s3"

  bucket_name  = var.movie_posters_bucket_name
  environment  = local.environment
  project_name = var.project_name
  is_public    = true
  tags         = local.tags
}

module "email_archives_s3" {
  source = "../../modules/s3"

  bucket_name  = var.email_archives_bucket_name
  environment  = local.environment
  project_name = var.project_name
  is_public    = false
  tags         = local.tags
}

module "movie_posters_cloudfront" {
  source = "../../modules/s3-cloudfront"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }


  project_name                         = var.project_name
  environment                          = local.environment
  frontend_bucket_name                 = module.movie_posters_s3.bucket_name
  logs_bucket_name                     = var.logs_bucket_name
  create_bucket                        = false
  create_logs_bucket                   = false
  existing_bucket_id                   = module.movie_posters_s3.bucket_name
  existing_bucket_arn                  = module.movie_posters_s3.bucket_arn
  existing_bucket_regional_domain_name = module.movie_posters_s3.bucket_regional_domain_name
  web_acl_arn                          = module.waf.web_acl_arn

  # price_class          = var.price_class

  tags = local.tags

}

module "email_archives_cloudfront" {
  source = "../../modules/s3-cloudfront"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }


  project_name                         = var.project_name
  environment                          = local.environment
  frontend_bucket_name                 = module.email_archives_s3.bucket_name
  logs_bucket_name                     = var.logs_bucket_name
  create_bucket                        = false
  create_logs_bucket                   = false
  existing_bucket_id                   = module.email_archives_s3.bucket_name
  existing_bucket_arn                  = module.email_archives_s3.bucket_arn
  existing_bucket_regional_domain_name = module.email_archives_s3.bucket_regional_domain_name
  web_acl_arn                          = module.waf.web_acl_arn

  # price_class          = var.price_class

  tags = local.tags

}

module "shield" {
  source = "../../modules/waf-shield"

  project_name           = var.project_name
  environment            = local.environment
  enable_waf             = false
  enable_shield_advanced = var.enable_shield_advanced
  cloudfront_resource_arns = compact([
    module.s3_cloudfront.cloudfront_distribution_arn,
    module.movie_posters_cloudfront.cloudfront_distribution_arn,
    module.email_archives_cloudfront.cloudfront_distribution_arn
  ])
  tags = local.tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name               = "${var.project_name}-${local.environment}"
  cluster_version            = "1.30"
  subnet_ids                 = module.vpc.private_subnet_ids
  vpc_id                     = module.vpc.vpc_id
  cluster_security_group_ids = [module.vpc.eks_cluster_security_group_id]
  node_security_group_ids    = [module.vpc.app_nodes_security_group_id]
  node_groups                = var.node_groups
  tags                       = local.tags
}

module "rds" {
  source = "../../modules/rds"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  identifier              = "${var.project_name}-${local.environment}-postgres"
  db_name                 = var.db_name
  username                = try(local.database_credentials.postgres_username, var.db_username)
  password                = local.database_credentials.postgres_password
  instance_class          = var.rds_instance_class
  subnet_ids              = module.vpc.database_subnet_ids
  security_group_ids      = [module.vpc.rds_security_group_id]
  create_dr_replica       = false
  backup_retention_period = 7
  tags                    = local.tags
}

module "documentdb" {
  source = "../../modules/documentdb"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  identifier            = "${var.project_name}-${local.environment}-docdb"
  cluster_name          = "${var.project_name}-${local.environment}-docdb"
  master_username       = try(local.database_credentials.docdb_master_username, var.docdb_master_username)
  master_password       = local.database_credentials.docdb_master_password
  subnet_ids            = module.vpc.database_subnet_ids
  security_group_ids    = [module.vpc.documentdb_security_group_id]
  enable_global_cluster = false
  instance_count        = 2
  tags                  = local.tags
}

module "redis" {
  source = "../../modules/redis"

  replication_group_id = "${var.project_name}-${local.environment}-redis"
  node_type            = var.redis_node_type
  subnet_ids           = module.vpc.database_subnet_ids
  security_group_ids   = [module.vpc.redis_security_group_id]
  tags                 = local.tags
}

module "msk" {
  source = "../../modules/msk"

  cluster_name           = "${var.project_name}-${local.environment}-msk"
  number_of_broker_nodes = var.msk_broker_count
  broker_instance_type   = var.msk_broker_instance_type
  subnet_ids             = module.vpc.private_subnet_ids
  security_group_ids     = [module.vpc.msk_security_group_id]
  tags                   = local.tags
}

locals {
  data_tier_ingress_from_eks_managed_sg = {
    postgres = {
      security_group_id = module.vpc.rds_security_group_id
      port              = 5432
      description       = "Allow PostgreSQL from the EKS-managed cluster/node security group."
    }
    documentdb = {
      security_group_id = module.vpc.documentdb_security_group_id
      port              = 27017
      description       = "Allow DocumentDB from the EKS-managed cluster/node security group."
    }
    redis = {
      security_group_id = module.vpc.redis_security_group_id
      port              = 6379
      description       = "Allow Redis from the EKS-managed cluster/node security group."
    }
    msk_tls = {
      security_group_id = module.vpc.msk_security_group_id
      port              = 9094
      description       = "Allow MSK TLS brokers from the EKS-managed cluster/node security group."
    }
  }
}

resource "aws_security_group_rule" "data_tier_from_eks_managed_cluster_sg" {
  for_each = local.data_tier_ingress_from_eks_managed_sg

  type                     = "ingress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = "tcp"
  security_group_id        = each.value.security_group_id
  source_security_group_id = module.eks.cluster_primary_security_group_id
  description              = each.value.description
}
