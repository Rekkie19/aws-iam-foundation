variable "aws_region" {
  type        = string
  description = "Region for the state bucket, the access-log bucket, and the KMS key. Backend config for every later root module must use this same region."

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", var.aws_region))
    error_message = "aws_region must look like a commercial AWS region name, for example us-east-1."
  }
}

variable "name_prefix" {
  type        = string
  description = "Prefix for the state bucket, the access-log bucket, and the KMS alias. Produces <prefix>-tfstate and <prefix>-tfstate-logs. Must be globally unique as an S3 bucket name prefix. Do not embed an account ID."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,35}[a-z0-9]$", var.name_prefix))
    error_message = "name_prefix must be 3-37 characters: lowercase letters, digits, and hyphens, starting and ending with a letter or digit."
  }
}
