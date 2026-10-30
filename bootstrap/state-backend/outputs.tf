output "state_bucket_name" {
  description = "Name of the Terraform state bucket."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state bucket. S3 bucket ARNs do not include the account ID."
  value       = aws_s3_bucket.state.arn
}

output "kms_key_arn" {
  description = "ARN of the customer-managed key for state objects. The ARN contains the account ID; do not commit it."
  value       = aws_kms_key.state.arn
  sensitive   = true
}

output "access_log_bucket_name" {
  description = "Name of the server access log bucket for the state bucket."
  value       = aws_s3_bucket.access_logs.id
}

output "access_log_bucket_arn" {
  description = "ARN of the server access log bucket."
  value       = aws_s3_bucket.access_logs.arn
}

output "backend_config_hcl" {
  description = "backend.hcl for migrating this module. Contains the KMS key ARN. Write it to a gitignored file; do not paste it into a pull request."
  value       = <<-EOT
    bucket       = "${aws_s3_bucket.state.id}"
    key          = "bootstrap/state-backend/terraform.tfstate"
    region       = "${var.aws_region}"
    encrypt      = true
    kms_key_id   = "${aws_kms_key.state.arn}"
    use_lockfile = true
  EOT
  sensitive   = true
}
