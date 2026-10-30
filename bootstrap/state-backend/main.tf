data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  partition  = data.aws_partition.current.partition
  account_id = data.aws_caller_identity.current.account_id

  # Deterministic names. The account ID stays out of the bucket name because
  # bucket names are globally visible and easy to guess.
  state_bucket_name = "${var.name_prefix}-tfstate"
  log_bucket_name   = "${var.name_prefix}-tfstate-logs"
  state_bucket_arn  = "arn:${local.partition}:s3:::${local.state_bucket_name}"
  log_bucket_arn    = "arn:${local.partition}:s3:::${local.log_bucket_name}"

  # AWS documents the log-delivery resource as "<prefix>*".
  log_prefix     = "s3-access/"
  log_object_arn = "${local.log_bucket_arn}/${local.log_prefix}*"

  kms_via_service = "s3.${var.aws_region}.${data.aws_partition.current.dns_suffix}"

  # Keep every noncurrent state version for 90 days, and always keep at least
  # the five newest, so a bad apply can be restored. Lock objects churn faster
  # than state; the same rule bounds that version growth.
  noncurrent_version_expiration_days = 90
  retained_noncurrent_versions       = 5
  abort_multipart_days               = 7
  access_log_expiration_days         = 365
}
