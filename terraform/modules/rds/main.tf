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

resource "aws_db_subnet_group" "primary" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.identifier}-subnet-group"
  })
}

resource "aws_db_parameter_group" "primary" {
  name   = "${var.identifier}-pg"
  family = "postgres16"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = local.common_tags
}

resource "aws_db_instance" "primary" {
  identifier                   = var.identifier
  engine                       = "postgres"
  engine_version               = var.engine_version
  instance_class               = var.instance_class
  allocated_storage            = var.allocated_storage
  max_allocated_storage        = var.max_allocated_storage
  db_name                      = var.db_name
  username                     = var.username
  password                     = var.password
  storage_encrypted            = true
  db_subnet_group_name         = aws_db_subnet_group.primary.name
  vpc_security_group_ids       = var.security_group_ids
  parameter_group_name         = aws_db_parameter_group.primary.name
  multi_az                     = var.multi_az
  backup_retention_period      = var.backup_retention_period
  backup_window                = "02:00-03:00"
  maintenance_window           = "Sun:03:00-Sun:04:00"
  deletion_protection          = false
  skip_final_snapshot          = true
  final_snapshot_identifier    = "${var.identifier}-final-snapshot"
  performance_insights_enabled = true

  tags = local.common_tags
}

resource "aws_db_subnet_group" "dr" {
  provider = aws.dr
  count    = var.create_dr_replica ? 1 : 0

  name       = "${var.identifier}-dr-subnet-group"
  subnet_ids = var.dr_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.identifier}-dr-subnet-group"
  })
}

resource "aws_db_instance" "dr_replica" {
  provider = aws.dr
  count    = var.create_dr_replica ? 1 : 0

  identifier              = "${var.identifier}-dr"
  instance_class          = var.dr_instance_class
  replicate_source_db     = aws_db_instance.primary.arn
  db_subnet_group_name    = aws_db_subnet_group.dr[0].name
  vpc_security_group_ids  = var.dr_security_group_ids
  backup_retention_period = var.backup_retention_period
  storage_encrypted       = true
  publicly_accessible     = false
  deletion_protection     = true

  tags = merge(local.common_tags, {
    Role = "dr-replica"
  })
}
