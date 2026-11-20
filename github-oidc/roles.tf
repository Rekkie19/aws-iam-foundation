data "aws_caller_identity" "current" {}

module "boundary" {
  source = "./modules/gha-dev-boundary"

  policy_name = var.boundary_policy_name
}

resource "aws_iam_role" "plan" {
  name                 = "gha-dev-plan"
  description          = "GitHub Actions plan role for the dev account. Trusts pull_request subjects only."
  assume_role_policy   = local.trust_policies.plan
  max_session_duration = 3600
  permissions_boundary = local.boundary_arn

  tags = {
    Role = "gha-dev-plan"
  }

  depends_on = [
    aws_iam_openid_connect_provider.github,
    module.boundary,
  ]

  lifecycle {
    precondition {
      condition     = data.aws_caller_identity.current.account_id == var.aws_account_id
      error_message = "aws_account_id must be the dev account this root is applied in."
    }

    precondition {
      condition     = alltrue([for subject in local.plan_subs : !strcontains(subject, "*")])
      error_message = "gha-dev-plan subjects must not contain a wildcard."
    }
  }
}

resource "aws_iam_role" "deploy" {
  name                 = "gha-dev-deploy"
  description          = "GitHub Actions apply role for the dev account. Trusts main and the dev environment, not pull requests."
  assume_role_policy   = local.trust_policies.deploy
  max_session_duration = 3600
  permissions_boundary = local.boundary_arn

  tags = {
    Role = "gha-dev-deploy"
  }

  depends_on = [
    aws_iam_openid_connect_provider.github,
    module.boundary,
  ]

  lifecycle {
    precondition {
      condition     = data.aws_caller_identity.current.account_id == var.aws_account_id
      error_message = "aws_account_id must be the dev account this root is applied in."
    }

    precondition {
      condition     = length(local.deploy_subs) > 0
      error_message = "gha-dev-deploy needs at least one ref or environment subject."
    }

    precondition {
      condition     = alltrue([for subject in local.deploy_subs : !strcontains(subject, "*")])
      error_message = "gha-dev-deploy subjects must not contain a wildcard."
    }
  }
}
