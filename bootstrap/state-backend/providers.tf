provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project    = "aws-iam-foundation"
      ManagedBy  = "terraform"
      Repository = "aws-iam-foundation"
      Component  = "state-backend"
    }
  }
}
