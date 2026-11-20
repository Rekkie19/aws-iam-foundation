variable "aws_region" {
  type        = string
  description = "Provider region. Must be the Identity Center home region. The instance is regional, and this module does not create it."

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", var.aws_region))
    error_message = "aws_region must look like a commercial AWS region name, for example us-east-1."
  }
}

variable "management_account_id" {
  type        = string
  description = "Management account ID. DevPowerUser assignments to this account are rejected. Do not commit a real ID; keep it in terraform.tfvars."

  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "management_account_id must be exactly 12 digits."
  }
}

variable "create_groups" {
  type        = bool
  default     = false
  description = "Create one Identity Store group per key in assignments. Leave false to look groups up by display name. This module never creates users."
}

variable "relay_state" {
  type        = string
  default     = null
  description = "Optional https URL Identity Center opens after sign-in. Null leaves the Identity Center default. Applied to every permission set."

  validation {
    condition     = var.relay_state == null || can(regex("^https://", var.relay_state))
    error_message = "relay_state must be null or an https URL."
  }
}

variable "dev_power_user_boundary_name" {
  type        = string
  default     = "DevPowerUserBoundary"
  description = "Name of the customer-managed permissions boundary in each account that receives DevPowerUser. Must match boundary/dev-power-user-boundary.json. The policy is not created by this root."

  validation {
    condition     = can(regex("^[\\w+=,.@-]+$", var.dev_power_user_boundary_name))
    error_message = "dev_power_user_boundary_name must be a valid IAM policy name."
  }
}

variable "assignments" {
  type = map(list(object({
    permission_set = string
    account_id     = string
  })))
  description = "Group display name to permission-set assignments. Account IDs are 12 digits. Use placeholders in the example only. DevPowerUser in the management account is rejected on the assignment resource."

  validation {
    condition = alltrue(flatten([
      for group, items in var.assignments : concat(
        [
          length(trimspace(group)) > 0,
          length(group) <= 128,
          !strcontains(group, "@"),
        ],
        [
          for item in items : (
            contains(["Admin", "ReadOnly", "SecurityAudit", "DevPowerUser"], item.permission_set)
            && can(regex("^[0-9]{12}$", item.account_id))
          )
        ],
      )
    ]))
    error_message = "Each assignments key must be a group display name without an email address. permission_set must be Admin, ReadOnly, SecurityAudit, or DevPowerUser. account_id must be 12 digits."
  }
}
