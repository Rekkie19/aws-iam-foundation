# Customer-managed key for the state bucket only.
#
# The account root statement lets IAM in this account administer the key.
# It does not authorize the AWS root user to use the key by itself, and it
# does not grant cryptographic operations. A principal still needs an identity
# policy, and cryptographic calls must come through S3 for this bucket.
#
# Omitting the account root can make the key unmanageable: a key policy is
# authoritative, and IAM cannot grant what the key policy does not allow.

data "aws_iam_policy_document" "state_key" {
  # KMS key policies accept only Resource "*". Checkov scores that the same
  # way it scores an identity policy. The statements below are the constraint:
  # administration is delegated to IAM in this account, and cryptographic use
  # has to come through S3 for this bucket.
  #checkov:skip=CKV_AWS_356:KMS key policies require Resource "*". Cryptographic use is limited by kms:ViaService, CallerAccount, and the state bucket encryption context.
  #checkov:skip=CKV_AWS_111:Key administration is an unconstrained action by design and still needs an identity policy. Cryptographic actions are condition-scoped.
  #checkov:skip=CKV_AWS_109:PutKeyPolicy and CreateGrant cannot name a key ARN inside a key policy. Identity policies remain the second gate.

  statement {
    sid    = "AccountAdministersKey"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
    }

    actions = [
      "kms:CancelKeyDeletion",
      "kms:CreateGrant",
      "kms:DescribeKey",
      "kms:DisableKey",
      "kms:DisableKeyRotation",
      "kms:EnableKey",
      "kms:EnableKeyRotation",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListGrants",
      "kms:ListKeyPolicies",
      "kms:ListResourceTags",
      "kms:PutKeyPolicy",
      "kms:RevokeGrant",
      "kms:RotateKeyOnDemand",
      "kms:ScheduleKeyDeletion",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:UpdateKeyDescription",
    ]

    resources = ["*"]
  }

  # Decrypt and GenerateDataKey do not send kms:GrantIsForAWSResource.
  # That condition lives on the CreateGrant statement below; putting it here
  # would deny every state read and write.
  statement {
    sid    = "UseKeyThroughS3ForThisBucket"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [local.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = [local.kms_via_service]
    }

    # IfExists so control-plane calls that omit the context (for example
    # PutBucketEncryption) still succeed. Object reads and writes include the
    # context, and those must name this bucket.
    condition {
      test     = "ArnLikeIfExists"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values = [
        local.state_bucket_arn,
        "${local.state_bucket_arn}/*",
      ]
    }
  }

  statement {
    sid    = "AllowS3ToCreateGrantsForBucketKeys"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
    }

    actions   = ["kms:CreateGrant"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [local.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = [local.kms_via_service]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_kms_key" "state" {
  description             = "Encrypts Terraform state for ${var.name_prefix}."
  deletion_window_in_days = 30
  enable_key_rotation     = true
  rotation_period_in_days = 365
  policy                  = data.aws_iam_policy_document.state_key.json

  # A state key is not disposable. Removing it is a reviewed change that
  # drops this lifecycle first, after state has been migrated off the key.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "state" {
  name          = "alias/${var.name_prefix}-tfstate"
  target_key_id = aws_kms_key.state.key_id
}
