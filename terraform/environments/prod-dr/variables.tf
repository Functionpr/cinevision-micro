variable "project_name" {
  type    = string
  default = "cinevision"
}
variable "aws_profile" {
  type    = string
  default = null
}
variable "primary_region" {
  type    = string
  default = "us-west-2"
}
variable "prod_state_bucket" {
  type    = string
  default = "ACCOUNT_ID-cinevision-terraform-state-prod"
  validation {
    condition     = !strcontains(var.prod_state_bucket, "ACCOUNT_ID")
    error_message = "prod_state_bucket still contains ACCOUNT_ID placeholder."
  }
}
variable "prod_state_key" {
  type    = string
  default = "terraform/prod/terraform.tfstate"
}
variable "prod_state_region" {
  type    = string
  default = "us-east-1"
}
variable "node_groups" {
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = number
    capacity_type  = string
  }))
  default = {
    general = {
      instance_types = ["t3.large"]
      desired_size   = 1
      min_size       = 1
      max_size       = 2
      disk_size      = 50
      capacity_type  = "ON_DEMAND"
    }
  }
}
variable "redis_node_type" {
  type    = string
  default = "cache.t4g.small"
}
variable "tags" {
  type = map(string)
  default = {
    Owner = "platform-team"
  }
}

variable "msk_broker_count" {
  type    = number
  default = 3
}

variable "msk_broker_instance_type" {
  type    = string
  default = "kafka.t3.small"
}
