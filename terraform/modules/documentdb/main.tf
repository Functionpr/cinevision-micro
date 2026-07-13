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
    ManagedBy = "Terraform"
  })
}

resource "aws_docdb_subnet_group" "primary" {
  name       = "${var.cluster_name}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = local.common_tags
}

resource "aws_docdb_cluster_parameter_group" "primary" {
  family      = "docdb5.0"
  name        = "${var.cluster_name}-pg"
  description = "Parameter group for ${var.cluster_name}"

  parameter {
    name  = "tls"
    value = "enabled"
  }

  tags = local.common_tags
}

resource "aws_docdb_global_cluster" "this" {
  count                     = var.enable_global_cluster ? 1 : 0
  global_cluster_identifier = "${var.cluster_name}-global"
  engine                    = "docdb"
  engine_version            = "5.0.0"
  storage_encrypted         = true
}

resource "aws_docdb_cluster" "primary" {
  cluster_identifier              = var.cluster_name
  master_username                 = var.master_username
  master_password                 = var.master_password
  db_subnet_group_name            = aws_docdb_subnet_group.primary.name
  vpc_security_group_ids          = var.security_group_ids
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.primary.name
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  storage_encrypted               = true
  global_cluster_identifier       = var.enable_global_cluster ? aws_docdb_global_cluster.this[0].id : null
  deletion_protection             = false
  apply_immediately               = true
  skip_final_snapshot             = true
  final_snapshot_identifier       = "${var.identifier}-final-snapshot"

  tags = local.common_tags
}

resource "aws_docdb_cluster_instance" "primary" {
  count              = var.instance_count
  identifier         = "${var.cluster_name}-${count.index + 1}"
  cluster_identifier = aws_docdb_cluster.primary.id
  instance_class     = var.instance_class

  tags = local.common_tags
}

resource "aws_docdb_subnet_group" "dr" {
  provider = aws.dr
  count    = var.enable_global_cluster ? 1 : 0

  name       = "${var.cluster_name}-dr-subnet-group"
  subnet_ids = var.dr_subnet_ids
  tags       = local.common_tags
}

resource "aws_docdb_cluster" "dr" {
  provider = aws.dr
  count    = var.enable_global_cluster ? 1 : 0

  cluster_identifier        = "${var.cluster_name}-dr"
  global_cluster_identifier = aws_docdb_global_cluster.this[0].id
  db_subnet_group_name      = aws_docdb_subnet_group.dr[0].name
  vpc_security_group_ids    = var.dr_security_group_ids
  storage_encrypted         = true
  deletion_protection       = true
  apply_immediately         = true

  tags = merge(local.common_tags, {
    Role = "dr-secondary"
  })
}

resource "aws_docdb_cluster_instance" "dr" {
  provider = aws.dr
  count    = var.enable_global_cluster ? var.dr_instance_count : 0

  identifier         = "${var.cluster_name}-dr-${count.index + 1}"
  cluster_identifier = aws_docdb_cluster.dr[0].id
  instance_class     = var.dr_instance_class

  tags = merge(local.common_tags, {
    Role = "dr-secondary"
  })
}
