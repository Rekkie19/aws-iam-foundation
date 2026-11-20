resource "aws_ssoadmin_account_assignment" "this" {
  for_each = local.assignments

  instance_arn       = local.instance_arn
  permission_set_arn = local.permission_set_arns[each.value.permission_set]
  principal_id       = local.group_ids[each.value.group]
  principal_type     = "GROUP"
  target_id          = each.value.account_id
  target_type        = "AWS_ACCOUNT"

  lifecycle {
    precondition {
      condition     = each.value.permission_set != "DevPowerUser" || each.value.account_id != var.management_account_id
      error_message = "DevPowerUser cannot be assigned in the management account. Use it in workload accounts. Admin is the one-hour set for management and break-glass."
    }
  }
}
