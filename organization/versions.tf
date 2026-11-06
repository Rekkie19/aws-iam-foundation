terraform {
  # use_lockfile on the state bucket requires Terraform 1.10 or later.
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Partial configuration. backend.hcl is gitignored because the KMS key ARN
  # contains the account ID.
  #   terraform init -backend-config=backend.hcl
  backend "s3" {}
}
