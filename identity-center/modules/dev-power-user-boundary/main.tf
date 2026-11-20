resource "aws_iam_policy" "boundary" {
  name        = var.policy_name
  path        = "/"
  description = "Permissions boundary for the Identity Center DevPowerUser permission set."
  policy      = file("${path.module}/../../boundary/dev-power-user-boundary.json")

  tags = var.tags

  lifecycle {
    precondition {
      condition     = strcontains(file("${path.module}/../../boundary/dev-power-user-boundary.json"), "policy/${var.policy_name}")
      error_message = "The boundary JSON must reference policy/${var.policy_name}."
    }
  }
}
