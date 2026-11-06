# Offline plan tests. mock_provider skips AWS. The policy JSON is built with
# jsonencode, so the assertions read the documents this module would submit.
# This is the stand-in for IAM Access Analyzer validate-policy: no network
# and no credentials. It checks effect, required actions, exemptions,
# attachment targets, and the 5120-character ceiling.

mock_provider "aws" {}

variables {
  aws_region      = "us-east-1"
  allowed_regions = ["us-east-1"]
  exempt_principal_arns = [
    "arn:aws:iam::*:role/BreakGlass",
  ]
  attach_ou_ids = {
    workloads_dev = "ou-dev0-example1"
  }
}

run "dev_ou_only" {
  command = plan

  assert {
    condition     = output.scp_character_limit == 5120
    error_message = "The module character ceiling must stay 5120."
  }

  assert {
    condition = alltrue([
      for name, count in output.policy_character_counts :
      count > 0 && count <= output.scp_character_limit
    ])
    error_message = "A guardrail document is empty or larger than 5120 characters."
  }

  assert {
    condition = (
      length(aws_organizations_policy_attachment.guardrail) == 4
      && alltrue([
        for key, attachment in aws_organizations_policy_attachment.guardrail :
        attachment.target_id == "ou-dev0-example1" && startswith(attachment.target_id, "ou-")
      ])
    )
    error_message = "Dev-only rollout must attach each of the four policies once, and only to the Dev OU."
  }

  assert {
    condition = alltrue([
      for document in [
        aws_organizations_policy.leave_organization.content,
        aws_organizations_policy.security_services.content,
        aws_organizations_policy.region_restriction.content,
        aws_organizations_policy.identity_baseline.content,
        ] : alltrue([
          for statement in jsondecode(document).Statement : statement.Effect == "Deny"
      ])
    ])
    error_message = "Every statement in these guardrails must be Deny. Allow statements belong to FullAWSAccess, which this module does not manage."
  }

  assert {
    condition = (
      contains(jsondecode(aws_organizations_policy.leave_organization.content).Statement[0].Action, "organizations:LeaveOrganization")
      && try(jsondecode(aws_organizations_policy.leave_organization.content).Statement[0].Condition, null) == null
      && !strcontains(aws_organizations_policy.leave_organization.content, "BreakGlass")
    )
    error_message = "LeaveOrganization must be denied with no principal exemption."
  }

  assert {
    condition = alltrue([
      for action in [
        "cloudtrail:StopLogging",
        "cloudtrail:DeleteTrail",
        "guardduty:DeleteDetector",
        "config:StopConfigurationRecorder",
        "config:DeleteConfigurationRecorder",
        "access-analyzer:DeleteAnalyzer",
      ] : strcontains(aws_organizations_policy.security_services.content, action)
    ]) && strcontains(aws_organizations_policy.security_services.content, "ArnNotLike") && strcontains(aws_organizations_policy.security_services.content, "arn:aws:iam::*:role/BreakGlass")
    error_message = "The security-service policy must deny the disable and delete actions and exempt only the configured role ARN."
  }

  assert {
    condition = alltrue([
      for action in [
        "budgets:*",
        "cloudfront:*",
        "iam:*",
        "organizations:*",
        "route53:*",
        "sts:*",
        "support:*",
      ] : strcontains(aws_organizations_policy.region_restriction.content, action)
    ]) && strcontains(aws_organizations_policy.region_restriction.content, "aws:RequestedRegion") && strcontains(aws_organizations_policy.region_restriction.content, "us-east-1") && strcontains(aws_organizations_policy.region_restriction.content, "ArnNotLike")
    error_message = "The region policy must deny other regions, exempt the global services, and exempt the configured role ARN."
  }

  assert {
    condition = (
      strcontains(aws_organizations_policy.identity_baseline.content, "iam:CreateUser")
      && strcontains(aws_organizations_policy.identity_baseline.content, "iam:CreateAccessKey")
      && strcontains(aws_organizations_policy.identity_baseline.content, "arn:aws:iam::*:root")
      && strcontains(aws_organizations_policy.identity_baseline.content, "public-read")
      && !strcontains(aws_organizations_policy.identity_baseline.content, "ArnNotLike")
      && !strcontains(aws_organizations_policy.identity_baseline.content, "BreakGlass")
      && !strcontains(aws_organizations_policy.identity_baseline.content, "PutBucketPublicAccessBlock")
    )
    error_message = "The identity policy must deny IAM users, access keys, root, and public ACLs, with no role exemption and no Block Public Access API deny."
  }
}

run "policies_without_attachments" {
  command = plan

  variables {
    attach_ou_ids = {}
  }

  assert {
    condition     = length(aws_organizations_policy_attachment.guardrail) == 0
    error_message = "An empty attach_ou_ids map must create no attachments."
  }

  assert {
    condition     = output.policy_character_counts.region_restriction <= 5120
    error_message = "The region policy must stay within 5120 characters when nothing is attached."
  }
}

run "reject_organization_root" {
  command = plan

  variables {
    attach_ou_ids = {
      root = "r-ex00"
    }
  }

  expect_failures = [
    var.attach_ou_ids,
  ]
}

run "reject_session_arn" {
  command = plan

  variables {
    exempt_principal_arns = [
      "arn:aws:sts::ACCOUNTID:assumed-role/BreakGlass/session",
    ]
  }

  expect_failures = [
    var.exempt_principal_arns,
  ]
}

run "reject_role_star" {
  command = plan

  variables {
    exempt_principal_arns = [
      "arn:aws:iam::*:role/*",
    ]
  }

  expect_failures = [
    var.exempt_principal_arns,
  ]
}
