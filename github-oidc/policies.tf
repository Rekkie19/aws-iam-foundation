resource "aws_iam_role_policy_attachment" "managed" {
  for_each = local.managed_policy_attachments

  role       = each.value.role
  policy_arn = each.value.policy_arn

  depends_on = [aws_iam_role.plan]
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "gha-dev-plan-state"
  role   = aws_iam_role.plan.id
  policy = local.plan_state_policy
}

resource "aws_iam_role_policy" "deploy_state" {
  name   = "gha-dev-deploy-state"
  role   = aws_iam_role.deploy.id
  policy = local.deploy_state_policy
}

resource "aws_iam_role_policy" "deploy_actions" {
  name   = "gha-dev-deploy-actions"
  role   = aws_iam_role.deploy.id
  policy = local.deploy_actions_policy
}
