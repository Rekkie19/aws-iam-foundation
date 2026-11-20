output "instance_arn" {
  description = "ARN of the existing Identity Center instance. This module does not create the instance."
  value       = local.instance_arn
}

output "identity_store_id" {
  description = "Identity Store ID for the existing instance."
  value       = local.identity_store_id
}

output "permission_set_arns" {
  description = "ARNs of the four permission sets."
  value       = local.permission_set_arns
}

output "group_ids" {
  description = "Identity Store group IDs keyed by display name."
  value       = local.group_ids
}

output "dev_power_user_boundary_name" {
  description = "Customer-managed policy name that must exist in each DevPowerUser account."
  value       = var.dev_power_user_boundary_name
}

output "dev_power_user_boundary_statements" {
  description = "Statement ids in the DevPowerUser boundary document."
  value       = [for statement in jsondecode(local.boundary_document).Statement : statement.Sid]
}
