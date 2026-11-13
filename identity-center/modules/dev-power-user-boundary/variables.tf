variable "aws_region" {
  type        = string
  description = "Region for this account's provider. IAM is global. Use the same region as the rest of the foundation."

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", var.aws_region))
    error_message = "aws_region must look like a commercial AWS region name, for example us-east-1."
  }
}

variable "policy_name" {
  type        = string
  default     = "DevPowerUserBoundary"
  description = "IAM policy name. Must match identity-center's dev_power_user_boundary_name and the ARN inside the JSON document."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Extra tags for the boundary policy. The provider default_tags still apply."
}
