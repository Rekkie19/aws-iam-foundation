data "aws_ssoadmin_instances" "this" {}

resource "aws_ssoadmin_permission_set" "admin" {
  name             = "Admin"
  description      = "AdministratorAccess for management and break-glass sessions. One hour."
  instance_arn     = local.instance_arn
  session_duration = local.session_duration.admin
  relay_state      = var.relay_state

  tags = {
    PermissionSet = "Admin"
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "admin" {
  #checkov:skip=CKV_AWS_274:Admin is the one-hour management and break-glass set. AdministratorAccess is the privilege that set exists to grant, not a workload default.
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  managed_policy_arn = local.managed_policy_arns.administrator_access
}

resource "aws_ssoadmin_permission_set" "readonly" {
  name             = "ReadOnly"
  description      = "ReadOnlyAccess for investigation. Four hours. ViewOnlyAccess is the narrower alternative."
  instance_arn     = local.instance_arn
  session_duration = local.session_duration.readonly
  relay_state      = var.relay_state

  tags = {
    PermissionSet = "ReadOnly"
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "readonly" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly.arn
  managed_policy_arn = local.managed_policy_arns.readonly_access
}

resource "aws_ssoadmin_permission_set" "security_audit" {
  name             = "SecurityAudit"
  description      = "SecurityAudit plus ReadOnlyAccess for the Security account. Four hours."
  instance_arn     = local.instance_arn
  session_duration = local.session_duration.security_audit
  relay_state      = var.relay_state

  tags = {
    PermissionSet = "SecurityAudit"
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "security_audit" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_audit.arn
  managed_policy_arn = local.managed_policy_arns.security_audit
}

resource "aws_ssoadmin_managed_policy_attachment" "security_audit_readonly" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_audit.arn
  managed_policy_arn = local.managed_policy_arns.readonly_access
}

resource "aws_ssoadmin_permission_set" "dev_power_user" {
  name             = "DevPowerUser"
  description      = "PowerUserAccess capped by the DevPowerUserBoundary policy in the target account. Four hours. Not for the management account."
  instance_arn     = local.instance_arn
  session_duration = local.session_duration.dev_power_user
  relay_state      = var.relay_state

  tags = {
    PermissionSet = "DevPowerUser"
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "dev_power_user" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.dev_power_user.arn
  managed_policy_arn = local.managed_policy_arns.power_user_access
}

resource "aws_ssoadmin_permissions_boundary_attachment" "dev_power_user" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.dev_power_user.arn

  permissions_boundary {
    customer_managed_policy_reference {
      name = var.dev_power_user_boundary_name
      path = "/"
    }
  }
}

resource "terraform_data" "boundary_document" {
  input = var.dev_power_user_boundary_name

  lifecycle {
    precondition {
      condition     = strcontains(local.boundary_document, "policy/${var.dev_power_user_boundary_name}")
      error_message = "boundary/dev-power-user-boundary.json must reference policy/${var.dev_power_user_boundary_name}. Create that policy in each DevPowerUser account before assigning the permission set."
    }
  }
}
