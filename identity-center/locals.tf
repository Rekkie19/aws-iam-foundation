locals {
  instance_arn      = one(data.aws_ssoadmin_instances.this.arns)
  identity_store_id = one(data.aws_ssoadmin_instances.this.identity_store_ids)

  session_duration = {
    admin          = "PT1H"
    readonly       = "PT4H"
    security_audit = "PT4H"
    dev_power_user = "PT4H"
  }

  managed_policy_arns = {
    administrator_access = "arn:aws:iam::aws:policy/AdministratorAccess"
    readonly_access      = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    security_audit       = "arn:aws:iam::aws:policy/SecurityAudit"
    power_user_access    = "arn:aws:iam::aws:policy/PowerUserAccess"
  }

  permission_set_arns = {
    Admin         = aws_ssoadmin_permission_set.admin.arn
    ReadOnly      = aws_ssoadmin_permission_set.readonly.arn
    SecurityAudit = aws_ssoadmin_permission_set.security_audit.arn
    DevPowerUser  = aws_ssoadmin_permission_set.dev_power_user.arn
  }

  group_ids = merge(
    { for name, group in aws_identitystore_group.this : name => group.group_id },
    { for name, group in data.aws_identitystore_group.this : name => group.group_id },
  )

  assignment_list = flatten([
    for group, items in var.assignments : [
      for item in items : {
        group          = group
        permission_set = item.permission_set
        account_id     = item.account_id
      }
    ]
  ])

  assignments = {
    for item in local.assignment_list :
    "${item.group}/${item.permission_set}/${item.account_id}" => item
  }

  boundary_document = file("${path.module}/boundary/dev-power-user-boundary.json")
}
