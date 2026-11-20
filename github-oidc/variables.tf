variable "aws_region" {
  type        = string
  description = "Region for this dev-account provider. IAM is global. Use the same region as the rest of the foundation."

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", var.aws_region))
    error_message = "aws_region must look like a commercial AWS region name, for example us-east-1."
  }
}

variable "aws_account_id" {
  type        = string
  description = "Dev account ID this root is applied in. Used to build role, provider, and boundary ARNs. A precondition checks it against the caller. Do not commit a real ID."

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be exactly 12 digits."
  }
}

variable "github_org" {
  type        = string
  description = "GitHub organization or user that may assume the roles. No wildcard. Example placeholder: example-org."

  validation {
    condition = alltrue([
      can(regex("^[A-Za-z0-9][A-Za-z0-9-]{0,38}$", var.github_org)),
      !strcontains(var.github_org, "*"),
    ])
    error_message = "github_org must be a non-empty GitHub organization or user name of at most 39 characters, with no wildcard."
  }
}

variable "github_repo" {
  type        = string
  description = "Single GitHub repository allowed to assume the roles. No wildcard. Example placeholder: example-repo."

  validation {
    condition = alltrue([
      can(regex("^[A-Za-z0-9_.-]{1,100}$", var.github_repo)),
      !strcontains(var.github_repo, "*"),
      !strcontains(var.github_repo, ".."),
    ])
    error_message = "github_repo must be a non-empty repository name with no wildcard."
  }
}

variable "plan_subjects" {
  type        = list(string)
  default     = ["pull_request"]
  description = "Subject suffixes for gha-dev-plan, appended after repo:ORG/REPO:. Default is pull_request only. No wildcards."

  validation {
    condition = alltrue([
      length(var.plan_subjects) > 0,
      alltrue([
        for suffix in var.plan_subjects : alltrue([
          can(regex("^[A-Za-z0-9_.:/-]+$", suffix)),
          !strcontains(suffix, "*"),
        ])
      ]),
    ])
    error_message = "plan_subjects must be one or more non-empty suffixes with no wildcard."
  }
}

variable "deploy_refs" {
  type        = list(string)
  default     = ["refs/heads/main"]
  description = "Git refs that may assume gha-dev-deploy, as refs/heads/NAME or refs/tags/NAME. Default is refs/heads/main. No wildcards."

  validation {
    condition = alltrue([
      for ref in var.deploy_refs : alltrue([
        can(regex("^refs/(heads|tags)/[A-Za-z0-9._/-]+$", ref)),
        !strcontains(ref, "*"),
        !strcontains(ref, ".."),
      ])
    ])
    error_message = "deploy_refs entries must be refs/heads/... or refs/tags/... with no wildcard."
  }
}

variable "deploy_environments" {
  type        = list(string)
  default     = ["dev"]
  description = "GitHub Environment names that may assume gha-dev-deploy. Default is dev. No wildcards. The environment's deployment branch rule must limit those runs to main."

  validation {
    condition = alltrue([
      for environment in var.deploy_environments : alltrue([
        can(regex("^[A-Za-z0-9][A-Za-z0-9_.-]{0,62}$", environment)),
        !strcontains(environment, "*"),
      ])
    ])
    error_message = "deploy_environments entries must be GitHub environment names with no wildcard."
  }
}

variable "thumbprint_list" {
  type        = list(string)
  default     = null
  description = "Optional OIDC thumbprints. Leave null. AWS does not validate thumbprints for token.actions.githubusercontent.com. Set this only to pin a value when the provider's fetched thumbprint causes a diff."

  validation {
    # || stays on one line so a null list is not measured. alltrue would evaluate length(null).
    condition = var.thumbprint_list == null || alltrue([
      length(var.thumbprint_list) > 0,
      alltrue([
        for thumbprint in var.thumbprint_list : can(regex("^[a-f0-9]{40}$", thumbprint))
      ]),
    ])
    error_message = "thumbprint_list must be null or one or more 40-character lowercase hex thumbprints."
  }
}

variable "boundary_policy_name" {
  type        = string
  default     = "GhaDevBoundary"
  description = "Permissions boundary name created in this dev account. Must match the policy ARN inside boundary/gha-dev-boundary.json."

  validation {
    condition     = can(regex("^[\\w+=,.@-]+$", var.boundary_policy_name))
    error_message = "boundary_policy_name must be a valid IAM policy name."
  }
}

variable "state_bucket_name" {
  type        = string
  description = "Terraform state bucket name. The bucket lives in the state account. This root only grants the roles identity-policy access to it."

  validation {
    condition = alltrue([
      can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name)),
      !strcontains(var.state_bucket_name, "*"),
    ])
    error_message = "state_bucket_name must be an S3 bucket name with no wildcard."
  }
}

variable "state_key_prefix" {
  type        = string
  default     = "envs/dev/"
  description = "State key prefix the roles may use, with a trailing slash. Lock writes are limited to objects under this prefix whose keys end in .tflock. Must not cover this root's own state key."

  validation {
    condition = alltrue([
      length(var.state_key_prefix) > 1,
      endswith(var.state_key_prefix, "/"),
      !startswith(var.state_key_prefix, "/"),
      !strcontains(var.state_key_prefix, "*"),
      !strcontains(var.state_key_prefix, ".."),
      can(regex("^[a-zA-Z0-9._/-]+$", var.state_key_prefix)),
      !startswith("github-oidc/", var.state_key_prefix),
    ])
    error_message = "state_key_prefix must be a relative prefix ending in /, with no wildcard, and must not cover github-oidc/terraform.tfstate."
  }
}

variable "state_kms_key_arn" {
  type        = string
  description = "KMS key ARN that encrypts the state bucket. Often a key in the state account, not this dev account. Do not commit a real ARN."

  validation {
    condition     = can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.state_kms_key_arn))
    error_message = "state_kms_key_arn must be a KMS key ARN in the aws partition."
  }
}

variable "deploy_actions" {
  type        = list(string)
  description = "Starting-point action allowlist for gha-dev-deploy. Replace it with the actions the dev pipeline changes. This is not AdministratorAccess. iam:PassRole is rejected here; use pass_role_arns."
  default = [
    "ec2:DescribeInstances",
    "ec2:DescribeInstanceStatus",
    "logs:CreateLogGroup",
    "logs:DescribeLogGroups",
    "logs:PutRetentionPolicy",
    "s3:GetBucketLocation",
    "s3:GetBucketVersioning",
    "s3:ListAllMyBuckets",
  ]

  validation {
    condition = alltrue([
      length(var.deploy_actions) > 0,
      alltrue([
        for action in var.deploy_actions : alltrue([
          can(regex("^[a-z0-9-]+:[A-Za-z0-9*]+$", action)),
          split(":", action)[1] != "*",
          !startswith(action, "iam:Pass"),
          !strcontains(lower(action), "administrator"),
          length(regexall("\\*", action)) <= 1,
          anytrue([
            length(regexall("\\*", action)) == 0,
            endswith(action, "*"),
          ]),
        ])
      ]),
    ])
    error_message = "deploy_actions must be service:Action entries. A service-wide star, iam:PassRole, and AdministratorAccess are rejected. A single trailing action wildcard such as ec2:Describe* is allowed."
  }
}

variable "deploy_resource_arns" {
  type        = list(string)
  default     = ["*"]
  description = "Resources for deploy_actions. The default star is a starting point. Narrow it to the ARNs the pipeline changes. iam:PassRole does not use this list."

  validation {
    condition = alltrue([
      length(var.deploy_resource_arns) > 0,
      alltrue([
        for resource in var.deploy_resource_arns : anytrue([
          resource == "*",
          alltrue([
            can(regex("^arn:aws[a-zA-Z-]*:[a-z0-9-]+:[a-z0-9-]*:[0-9]*:.+$", resource)),
            !strcontains(resource, "*"),
          ]),
        ])
      ]),
    ])
    error_message = "deploy_resource_arns must be \"*\" or ARNs with no wildcard."
  }
}

variable "pass_role_arns" {
  type        = list(string)
  default     = []
  description = "Role ARNs gha-dev-deploy may pass. Empty by default. Each entry is one role ARN with no wildcard. The boundary still requires that role to wear GhaDevBoundary."

  validation {
    condition = alltrue([
      for role_arn in var.pass_role_arns : alltrue([
        can(regex("^arn:aws:iam::[0-9]{12}:role/[A-Za-z0-9+=,.@_/-]+$", role_arn)),
        !strcontains(role_arn, "*"),
      ])
    ])
    error_message = "pass_role_arns must be IAM role ARNs with no wildcard."
  }
}
