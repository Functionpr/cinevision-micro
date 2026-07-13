terraform {
  backend "s3" {
    bucket         = "211026994790-cinevision-terraform-state-staging"
    key            = "terraform/staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cinevision-terraform-locks-staging"
    encrypt        = true
    profile        = "cinevision-staging"
  }
}
