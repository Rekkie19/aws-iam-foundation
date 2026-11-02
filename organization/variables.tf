variable "aws_region" {
  type        = string
  description = "Provider region for this root. Use the same region as the state bucket. The organization itself is global. IAM Identity Center's home region is chosen in a later milestone."

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", var.aws_region))
    error_message = "aws_region must look like a commercial AWS region name, for example us-east-1."
  }
}

variable "account_emails" {
  type = object({
    security = string
    dev      = string
    prod     = string
  })
  description = "Email addresses for the Security, Dev, and Prod member accounts. Each address must be able to receive mail and must not already belong to an AWS account. No default: a real address does not belong in git. Sensitive so plan output redacts the addresses."
  sensitive   = true

  validation {
    condition = alltrue([
      can(regex("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$", var.account_emails.security)),
      can(regex("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$", var.account_emails.dev)),
      can(regex("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$", var.account_emails.prod)),
      length(var.account_emails.security) >= 6 && length(var.account_emails.security) <= 64,
      length(var.account_emails.dev) >= 6 && length(var.account_emails.dev) <= 64,
      length(var.account_emails.prod) >= 6 && length(var.account_emails.prod) <= 64,
      length(distinct([
        lower(var.account_emails.security),
        lower(var.account_emails.dev),
        lower(var.account_emails.prod),
      ])) == 3,
    ])
    error_message = "account_emails.security, account_emails.dev, and account_emails.prod must be three different email addresses, each 6 to 64 characters."
  }
}
