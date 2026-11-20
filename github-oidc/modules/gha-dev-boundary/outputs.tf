output "policy_name" {
  description = "Name of the permissions boundary created in this account."
  value       = aws_iam_policy.boundary.name
}

output "policy_arn" {
  description = "ARN of the permissions boundary. Contains the account ID."
  value       = aws_iam_policy.boundary.arn
  sensitive   = true
}
