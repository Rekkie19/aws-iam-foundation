output "policy_name" {
  description = "Name of the permissions boundary."
  value       = aws_iam_policy.boundary.name
}

output "policy_arn" {
  description = "ARN of the permissions boundary. The ARN contains the account ID. Do not commit it."
  value       = aws_iam_policy.boundary.arn
  sensitive   = true
}
