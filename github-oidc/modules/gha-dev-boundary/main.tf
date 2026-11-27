resource "aws_iam_policy" "boundary" {
  name        = var.policy_name
  path        = "/"
  description = "Permissions boundary for the GitHub Actions dev plan and deploy roles. Allow star is the ceiling. Deny statements are the control."
  policy      = file("${path.module}/../../boundary/gha-dev-boundary.json")

  tags = var.tags

  lifecycle {
    precondition {
      condition     = strcontains(file("${path.module}/../../boundary/gha-dev-boundary.json"), "policy/${var.policy_name}")
      error_message = "The boundary JSON must reference policy/${var.policy_name}."
    }
  }
}
