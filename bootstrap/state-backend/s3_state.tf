resource "aws_s3_bucket" "state" {
  #checkov:skip=CKV_AWS_144:Single-region bootstrap. Versioning with 90-day noncurrent retention is the recovery control. A replica would be a second copy of Terraform state.
  #checkov:skip=CKV2_AWS_62:Event notifications are not the audit path. Server access logs cover this bucket now. Organization CloudTrail data events are milestone 10.
  bucket        = local.state_bucket_name
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }

  # Object Lock is intentionally off. A compliance retention lock would stop
  # Terraform from writing the next state version. Versioning is the recovery path.
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days           = local.noncurrent_version_expiration_days
      newer_noncurrent_versions = local.retained_noncurrent_versions
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = local.abort_multipart_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}

resource "aws_s3_bucket_logging" "state" {
  bucket        = aws_s3_bucket.state.id
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = local.log_prefix

  depends_on = [aws_s3_bucket_policy.access_logs]
}

data "aws_iam_policy_document" "state_bucket" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      local.state_bucket_arn,
      "${local.state_bucket_arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "DenyUploadsWithoutKmsKeyHeader"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${local.state_bucket_arn}/*"]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = ["true"]
    }
  }

  statement {
    sid    = "DenyUploadsWithWrongKmsKey"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${local.state_bucket_arn}/*"]

    # Clients send either the key ARN or the key ID. Terraform's kms_key_id
    # must be the ARN from the output, which is one of these two values.
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values = [
        aws_kms_key.state.arn,
        aws_kms_key.state.key_id,
      ]
    }
  }

  statement {
    sid    = "DenyCustomerProvidedEncryption"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${local.state_bucket_arn}/*"]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption-customer-algorithm"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.state]
}
