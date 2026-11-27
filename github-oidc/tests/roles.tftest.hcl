# Offline plan tests. The AWS provider is mocked. No account, org, or
# repository in this file is real.

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "222222222222"
      arn        = "arn:aws:iam::222222222222:user/placeholder"
      id         = "222222222222"
      user_id    = "placeholder"
    }
  }
}

variables {
  aws_region        = "us-east-1"
  aws_account_id    = "222222222222"
  github_org        = "example-org"
  github_repo       = "example-repo"
  state_bucket_name = "name-prefix-tfstate"
  state_key_prefix  = "envs/dev/"
  state_kms_key_arn = "arn:aws:kms:us-east-1:111111111111:key/00000000-0000-0000-0000-000000000000"
}

run "roles" {
  command = plan

  assert {
    condition = (
      aws_iam_openid_connect_provider.github.url == "https://token.actions.githubusercontent.com"
      && toset(aws_iam_openid_connect_provider.github.client_id_list) == toset(["sts.amazonaws.com"])
    )
    error_message = "The OIDC provider must be the GitHub Actions issuer with audience sts.amazonaws.com."
  }

  assert {
    condition = (
      toset(keys(jsondecode(aws_iam_role.plan.assume_role_policy).Statement[0].Condition)) == toset(["StringEquals"])
      && toset(keys(jsondecode(aws_iam_role.deploy.assume_role_policy).Statement[0].Condition)) == toset(["StringEquals"])
    )
    error_message = "Trust policies must use StringEquals and must not use StringLike."
  }

  assert {
    condition = (
      jsondecode(aws_iam_role.plan.assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:aud"] == "sts.amazonaws.com"
      && jsondecode(aws_iam_role.deploy.assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:aud"] == "sts.amazonaws.com"
    )
    error_message = "Both roles must require audience sts.amazonaws.com."
  }

  assert {
    condition = toset(jsondecode(aws_iam_role.plan.assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"]) == toset([
      "repo:example-org/example-repo:pull_request",
    ])
    error_message = "gha-dev-plan must trust only the pull_request subject for the configured repository."
  }

  assert {
    condition = toset(jsondecode(aws_iam_role.deploy.assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"]) == toset([
      "repo:example-org/example-repo:ref:refs/heads/main",
      "repo:example-org/example-repo:environment:dev",
    ])
    error_message = "gha-dev-deploy must trust only refs/heads/main and environment dev."
  }

  assert {
    condition = (
      aws_iam_role.plan.max_session_duration == 3600
      && aws_iam_role.deploy.max_session_duration == 3600
    )
    error_message = "Both roles must limit the session to 3600 seconds."
  }

  assert {
    condition = (
      aws_iam_role.plan.permissions_boundary == "arn:aws:iam::222222222222:policy/GhaDevBoundary"
      && aws_iam_role.deploy.permissions_boundary == "arn:aws:iam::222222222222:policy/GhaDevBoundary"
    )
    error_message = "Both roles must wear the GhaDevBoundary permissions boundary."
  }

  assert {
    condition = (
      length(aws_iam_role_policy_attachment.managed) == 1
      && aws_iam_role_policy_attachment.managed["plan"].policy_arn == "arn:aws:iam::aws:policy/ReadOnlyAccess"
      && alltrue([
        for attachment in aws_iam_role_policy_attachment.managed :
        !strcontains(attachment.policy_arn, "AdministratorAccess")
      ])
      && !strcontains(aws_iam_role_policy.deploy_actions.policy, "AdministratorAccess")
      && !strcontains(aws_iam_role_policy.deploy_actions.policy, "iam:PassRole")
    )
    error_message = "The only managed policy is ReadOnlyAccess on the plan role. Deploy has no AdministratorAccess and no iam:PassRole."
  }

  assert {
    condition = (
      strcontains(aws_iam_role_policy.plan_state.policy, "*.tflock")
      && strcontains(aws_iam_role_policy.plan_state.policy, "s3:PutObject")
      && strcontains(aws_iam_role_policy.plan_state.policy, "s3:DeleteObject")
    )
    error_message = "The plan role must be able to write the lock object under the state prefix."
  }
}

run "reject_wildcard_org" {
  command = plan

  variables {
    github_org = "example-*"
  }

  expect_failures = [
    var.github_org,
  ]
}

run "reject_wildcard_repo" {
  command = plan

  variables {
    github_repo = "*"
  }

  expect_failures = [
    var.github_repo,
  ]
}

run "reject_empty_org" {
  command = plan

  variables {
    github_org = ""
  }

  expect_failures = [
    var.github_org,
  ]
}

run "reject_wildcard_ref" {
  command = plan

  variables {
    deploy_refs = ["refs/heads/*"]
  }

  expect_failures = [
    var.deploy_refs,
  ]
}
