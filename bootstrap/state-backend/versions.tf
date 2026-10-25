terraform {
  # use_lockfile requires Terraform 1.10 or later. S3-native locking is stable;
  # DynamoDB locking is deprecated and this module does not create a table.
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
