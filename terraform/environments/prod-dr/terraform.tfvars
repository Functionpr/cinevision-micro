project_name      = "cinevision"
aws_profile       = "cinevision-prod"
primary_region    = "us-west-2"
prod_state_bucket = "211026994790-cinevision-terraform-state-prod"
prod_state_key    = "terraform/prod/terraform.tfstate"
prod_state_region = "us-east-1"
redis_node_type   = "cache.t4g.small"
node_groups = {
  general = {
    instance_types = ["t3.large"]
    desired_size   = 1
    min_size       = 1
    max_size       = 2
    disk_size      = 50
    capacity_type  = "ON_DEMAND"
  }
}
tags = {
  Owner = "platform-team"
}
