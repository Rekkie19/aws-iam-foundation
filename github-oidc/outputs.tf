output "oidc_provider_arn" {
  description = "GitHub OIDC provider ARN in the dev account. Contains the account ID."
  value       = aws_iam_openid_connect_provider.github.arn
  sensitive   = true
}

output "plan_role_arn" {
  description = "ARN to store in the GitHub variable AWS_DEV_PLAN_ROLE_ARN. Contains the account ID."
  value       = aws_iam_role.plan.arn
  sensitive   = true
}

output "deploy_role_arn" {
  description = "ARN to store in the GitHub variable AWS_DEV_DEPLOY_ROLE_ARN. Contains the account ID."
  value       = aws_iam_role.deploy.arn
  sensitive   = true
}

output "boundary_policy_name" {
  description = "Permissions boundary attached to both roles."
  value       = module.boundary.policy_name
}

output "plan_subjects" {
  description = "Exact sub claims gha-dev-plan accepts."
  value       = local.plan_subs
}

output "deploy_subjects" {
  description = "Exact sub claims gha-dev-deploy accepts."
  value       = local.deploy_subs
}
