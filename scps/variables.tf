variable "aws_region" {
  type        = string
  description = "Provider region for this root. Use the same region as the state bucket. Service control policies are organization-wide; this region is not the allow-list."

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", var.aws_region))
    error_message = "aws_region must look like a commercial AWS region name, for example us-east-1."
  }
}

variable "allowed_regions" {
  type        = list(string)
  description = "Regions a member account may call. Any other aws:RequestedRegion is denied unless the API is in the global-service exemption list or the caller is in exempt_principal_arns. Include the state-bucket region and the future Identity Center home region."

  validation {
    condition = length(var.allowed_regions) > 0 && alltrue([
      for region in var.allowed_regions : can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", region))
    ])
    error_message = "allowed_regions must contain at least one commercial AWS region name, for example us-east-1."
  }
}

variable "exempt_principal_arns" {
  type        = list(string)
  description = "IAM role ARNs excluded from the region restriction and from the security-service deny. aws:PrincipalArn is the role ARN (arn:aws:iam::...:role/Name), not the assumed-role session ARN. No real account ID belongs in git. arn:aws:iam::*:role/BreakGlass matches that role name in every member account. This module does not create the role."

  validation {
    condition = length(var.exempt_principal_arns) > 0 && alltrue([
      for arn in var.exempt_principal_arns :
      can(regex("^arn:aws:iam::[0-9A-Za-z*]+:role/[0-9A-Za-z+=,.@_*/-]+$", arn))
      && !can(regex(":role/[*]+$", arn))
    ])
    error_message = "Each exempt_principal_arns entry must be an IAM role ARN (arn:aws:iam::account-or-star:role/RoleName). Use the role ARN, not an arn:aws:sts:: assumed-role session ARN. A role name of only * is rejected."
  }
}

variable "attach_ou_ids" {
  type        = map(string)
  description = "Organizational unit ids that receive every guardrail. Copy them from the organization output organizational_unit_ids. Use only workloads_dev on the first apply. An empty map creates the policies and attaches them to nothing. The organization root and account ids are rejected."

  validation {
    condition = alltrue([
      for id in values(var.attach_ou_ids) : can(regex("^ou-[0-9a-z]{4,32}-[0-9a-z]{8,32}$", id))
    ])
    error_message = "Each attach_ou_ids value must be an organizational unit id (ou-xxxx-yyyyyyyy). Do not pass the organization root (r-...) or an account id. This module does not attach SCPs to the root. SCPs do not apply to the management account."
  }
}
