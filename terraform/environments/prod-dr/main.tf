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
  profile = var.aws_profile
  region  = var.primary_region
}

data "terraform_remote_state" "prod" {
  backend = "s3"

  config = {
    bucket  = var.prod_state_bucket
    key     = var.prod_state_key
    region  = var.prod_state_region
    profile = var.aws_profile
  }
}

locals {
  environment = "prod-dr"
  tags = merge(var.tags, {
    Environment = local.environment
    CostCenter  = "production"
    Tier        = "warm-standby"
  })
}

module "eks" {
  source = "../../modules/eks"

  cluster_name               = "${var.project_name}-${local.environment}"
  cluster_version            = "1.30"
  subnet_ids                 = data.terraform_remote_state.prod.outputs.dr_private_subnet_ids
  vpc_id                     = data.terraform_remote_state.prod.outputs.dr_vpc_id
  cluster_security_group_ids = [data.terraform_remote_state.prod.outputs.dr_eks_cluster_security_group_id]
  node_security_group_ids    = [data.terraform_remote_state.prod.outputs.dr_app_nodes_security_group_id]
  node_groups                = var.node_groups
  tags                       = local.tags
}

module "redis" {
  source = "../../modules/redis"

  replication_group_id = "${var.project_name}-${local.environment}-redis"
  node_type            = var.redis_node_type
  subnet_ids           = data.terraform_remote_state.prod.outputs.dr_database_subnet_ids
  security_group_ids   = [data.terraform_remote_state.prod.outputs.dr_redis_security_group_id]
  tags                 = local.tags
}


module "msk" {
  source = "../../modules/msk"

  cluster_name           = "${var.project_name}-${local.environment}-msk"
  number_of_broker_nodes = var.msk_broker_count
  broker_instance_type   = var.msk_broker_instance_type
  subnet_ids             = data.terraform_remote_state.prod.outputs.dr_private_subnet_ids
  security_group_ids     = [data.terraform_remote_state.prod.outputs.dr_msk_security_group_id]
  tags                   = local.tags
}

locals {
  dr_data_tier_ingress_from_eks_managed_sg = {
    postgres = {
      security_group_id = data.terraform_remote_state.prod.outputs.dr_rds_security_group_id
      port              = 5432
      description       = "Allow DR PostgreSQL from the prod-dr EKS-managed cluster/node security group."
    }
    documentdb = {
      security_group_id = data.terraform_remote_state.prod.outputs.dr_documentdb_security_group_id
      port              = 27017
      description       = "Allow DR DocumentDB from the prod-dr EKS-managed cluster/node security group."
    }
    redis = {
      security_group_id = data.terraform_remote_state.prod.outputs.dr_redis_security_group_id
      port              = 6379
      description       = "Allow DR Redis from the prod-dr EKS-managed cluster/node security group."
    }
    msk_tls = {
      security_group_id = data.terraform_remote_state.prod.outputs.dr_msk_security_group_id
      port              = 9094
      description       = "Allow DR MSK TLS brokers from the prod-dr EKS-managed cluster/node security group."
    }
  }
}

resource "aws_security_group_rule" "dr_data_tier_from_eks_managed_cluster_sg" {
  for_each = local.dr_data_tier_ingress_from_eks_managed_sg

  type                     = "ingress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = "tcp"
  security_group_id        = each.value.security_group_id
  source_security_group_id = module.eks.cluster_primary_security_group_id
  description              = each.value.description
}
