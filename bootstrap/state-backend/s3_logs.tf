# Server access logs for the state bucket.
#
# The destination uses SSE-S3. AWS requires that for S3 server access log
# delivery: a destination whose default encryption is SSE-KMS can store logs
# under a key the account cannot read. Organization CloudTrail data events for
# both buckets are still milestone 10; these logs cover the gap until then.
#
# The log bucket does not log to itself. That would recurse.

resource "aws_s3_bucket" "access_logs" {
  #checkov:skip=CKV_AWS_145:S3 server access log delivery supports SSE-S3 only. SSE-KMS on this bucket can store logs under a key the account cannot read.
  #checkov:skip=CKV_AWS_144:Single-region bootstrap. Access logs are retained for 365 days here. Cross-region replication of logs is out of scope.
  #checkov:skip=CKV2_AWS_62:This bucket is the access-log destination. Event notifications are deferred to the organization trail in milestone 10.
  bucket        = local.log_bucket_name
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "expire-access-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = local.access_log_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = local.abort_multipart_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.access_logs]
}

data "aws_iam_policy_document" "access_logs" {
  statement {
    sid    = "AllowS3LogDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = [local.log_object_arn]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [local.state_bucket_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      local.log_bucket_arn,
      "${local.log_bucket_arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Log delivery relies on the bucket default key and may omit the encryption
  # header. Deny only a header that names some other algorithm.
  statement {
    sid    = "DenyWrongEncryptionHeader"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${local.log_bucket_arn}/*"]

    condition {
      test     = "StringNotEqualsIfExists"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }
  }
}

resource "aws_s3_bucket_policy" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  policy = data.aws_iam_policy_document.access_logs.json

  depends_on = [aws_s3_bucket_public_access_block.access_logs]
}
