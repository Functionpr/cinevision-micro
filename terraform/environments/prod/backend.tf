terraform {
  backend "s3" {
    bucket         = "211026994790-cinevision-terraform-state-prod"
    key            = "terraform/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cinevision-terraform-locks-prod"
    encrypt        = true
    profile        = "cinevision-prod"
  }
}
