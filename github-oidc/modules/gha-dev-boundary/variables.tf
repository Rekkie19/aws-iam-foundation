variable "policy_name" {
  type        = string
  description = "IAM policy name. Must match the policy ARN embedded in the boundary JSON."

  validation {
    condition     = can(regex("^[\\w+=,.@-]+$", var.policy_name))
    error_message = "policy_name must be a valid IAM policy name."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Extra tags for the boundary policy. Provider default_tags still apply."
}
