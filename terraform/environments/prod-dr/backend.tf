terraform {
  backend "s3" {
    bucket         = "211026994790-cinevision-terraform-state-prod-dr"
    key            = "terraform/prod-dr/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "cinevision-terraform-locks-prod-dr"
    encrypt        = true
    profile        = "cinevision-prod"
  }
}
