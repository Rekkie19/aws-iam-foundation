locals {
  # Commercial partition. Region validation already rejects GovCloud names.
  oidc_provider_arn = "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
  boundary_arn      = "arn:aws:iam::${var.aws_account_id}:policy/${var.boundary_policy_name}"

  plan_subs = sort([
    for suffix in var.plan_subjects :
    "repo:${var.github_org}/${var.github_repo}:${suffix}"
  ])

  deploy_subs = sort(concat(
    [for ref in var.deploy_refs : "repo:${var.github_org}/${var.github_repo}:ref:${ref}"],
    [for environment in var.deploy_environments : "repo:${var.github_org}/${var.github_repo}:environment:${environment}"],
  ))

  # One managed policy, on the plan role only. Deploy stays on deploy_actions.
  managed_policy_attachments = {
    plan = {
      role       = "gha-dev-plan"
      policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    }
  }

  state_bucket_arn = "arn:aws:s3:::${var.state_bucket_name}"
  state_object_arn = "arn:aws:s3:::${var.state_bucket_name}/${var.state_key_prefix}*"
  state_lock_arn   = "arn:aws:s3:::${var.state_bucket_name}/${var.state_key_prefix}*.tflock"

  # DescribeKey is a direct call. Crypto calls go through S3.
  kms_via_s3 = {
    StringEquals = {
      "kms:ViaService" = "s3.${var.aws_region}.amazonaws.com"
    }
  }

  pass_role_statements = length(var.pass_role_arns) == 0 ? [] : [
    {
      Sid      = "PassNamedRoles"
      Effect   = "Allow"
      Action   = "iam:PassRole"
      Resource = var.pass_role_arns
    },
  ]
}

# Trust documents use StringEquals on the full sub. No StringLike.
locals {
  trust_policies = {
    for name, subjects in {
      plan   = local.plan_subs
      deploy = local.deploy_subs
    } :
    name => jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "GitHubActionsOidc"
          Effect = "Allow"
          Principal = {
            Federated = local.oidc_provider_arn
          }
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
              "token.actions.githubusercontent.com:sub" = subjects
            }
          }
        },
      ]
    })
  }

  plan_state_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListStatePrefix"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = local.state_bucket_arn
        Condition = {
          StringLike = {
            "s3:prefix" = [
              var.state_key_prefix,
              "${var.state_key_prefix}*",
            ]
          }
        }
      },
      {
        Sid    = "ReadStateBucketConfig"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:GetEncryptionConfiguration",
        ]
        Resource = local.state_bucket_arn
      },
      {
        Sid      = "ReadStateObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = local.state_object_arn
      },
      {
        Sid    = "WriteLockObject"
        Effect = "Allow"
        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = local.state_lock_arn
      },
      {
        Sid      = "DescribeStateKey"
        Effect   = "Allow"
        Action   = ["kms:DescribeKey"]
        Resource = var.state_kms_key_arn
      },
      {
        Sid       = "DecryptState"
        Effect    = "Allow"
        Action    = ["kms:Decrypt"]
        Resource  = var.state_kms_key_arn
        Condition = local.kms_via_s3
      },
      {
        Sid    = "EncryptLockObject"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:GenerateDataKey",
        ]
        Resource  = var.state_kms_key_arn
        Condition = local.kms_via_s3
      },
    ]
  })

  deploy_state_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListStatePrefix"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = local.state_bucket_arn
        Condition = {
          StringLike = {
            "s3:prefix" = [
              var.state_key_prefix,
              "${var.state_key_prefix}*",
            ]
          }
        }
      },
      {
        Sid    = "ReadStateBucketConfig"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:GetEncryptionConfiguration",
        ]
        Resource = local.state_bucket_arn
      },
      {
        Sid    = "ReadWriteStateObjects"
        Effect = "Allow"
        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = local.state_object_arn
      },
      {
        Sid      = "DescribeStateKey"
        Effect   = "Allow"
        Action   = ["kms:DescribeKey"]
        Resource = var.state_kms_key_arn
      },
      {
        Sid    = "UseStateKey"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
        ]
        Resource  = var.state_kms_key_arn
        Condition = local.kms_via_s3
      },
    ]
  })

  deploy_actions_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid      = "StartingPoint"
          Effect   = "Allow"
          Action   = var.deploy_actions
          Resource = var.deploy_resource_arns
        },
      ],
      local.pass_role_statements,
    )
  })
}
