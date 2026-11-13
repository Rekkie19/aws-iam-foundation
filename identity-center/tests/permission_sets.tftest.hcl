# Offline plan tests. The AWS provider is mocked, including the existing
# Identity Center instance. No account in this file is a real account.

mock_provider "aws" {
  mock_data "aws_ssoadmin_instances" {
    defaults = {
      arns               = ["arn:aws:sso:::instance/ssoins-example"]
      identity_store_ids = ["d-example"]
    }
  }
}

variables {
  aws_region            = "us-east-1"
  management_account_id = "111111111111"
  create_groups         = true
  assignments = {
    Placeholder-BreakGlass = [
      {
        permission_set = "Admin"
        account_id     = "111111111111"
      }
    ]
    Placeholder-Readers = [
      {
        permission_set = "ReadOnly"
        account_id     = "222222222222"
      }
    ]
    Placeholder-Security = [
      {
        permission_set = "SecurityAudit"
        account_id     = "333333333333"
      }
    ]
    Placeholder-Dev = [
      {
        permission_set = "DevPowerUser"
        account_id     = "222222222222"
      }
    ]
  }
}

run "permission_sets" {
  command = plan

  assert {
    condition = (
      aws_ssoadmin_permission_set.admin.session_duration == "PT1H"
      && aws_ssoadmin_permission_set.readonly.session_duration == "PT4H"
      && aws_ssoadmin_permission_set.security_audit.session_duration == "PT4H"
      && aws_ssoadmin_permission_set.dev_power_user.session_duration == "PT4H"
    )
    error_message = "Admin must be PT1H. ReadOnly, SecurityAudit, and DevPowerUser must be PT4H."
  }

  assert {
    condition = (
      aws_ssoadmin_managed_policy_attachment.admin.managed_policy_arn == "arn:aws:iam::aws:policy/AdministratorAccess"
      && aws_ssoadmin_managed_policy_attachment.readonly.managed_policy_arn == "arn:aws:iam::aws:policy/ReadOnlyAccess"
      && aws_ssoadmin_managed_policy_attachment.security_audit.managed_policy_arn == "arn:aws:iam::aws:policy/SecurityAudit"
      && aws_ssoadmin_managed_policy_attachment.security_audit_readonly.managed_policy_arn == "arn:aws:iam::aws:policy/ReadOnlyAccess"
      && aws_ssoadmin_managed_policy_attachment.dev_power_user.managed_policy_arn == "arn:aws:iam::aws:policy/PowerUserAccess"
    )
    error_message = "Permission sets must attach the AWS managed policies from the design."
  }

  assert {
    condition     = aws_ssoadmin_permissions_boundary_attachment.dev_power_user.permissions_boundary[0].customer_managed_policy_reference[0].name == "DevPowerUserBoundary"
    error_message = "DevPowerUser must reference the customer-managed permissions boundary."
  }

  assert {
    condition = alltrue([
      for sid in [
        "DenyIamUsersAndKeys",
        "DenyOrganizationChanges",
        "DenyDisableSecurityServices",
        "DenyBoundaryPolicyEdits",
        "DenyBoundarySwap",
        "DenyRoleWithoutThisBoundary",
        "DenyRoleWhenBoundaryMissing",
      ] : contains(output.dev_power_user_boundary_statements, sid)
    ])
    error_message = "The boundary document is missing a required deny statement."
  }
}

run "reject_bad_account_id" {
  command = plan

  variables {
    assignments = {
      Placeholder-Dev = [
        {
          permission_set = "DevPowerUser"
          account_id     = "1234"
        }
      ]
    }
  }

  expect_failures = [
    var.assignments,
  ]
}

run "reject_dev_power_user_on_management" {
  command = plan

  variables {
    assignments = {
      Placeholder-Dev = [
        {
          permission_set = "DevPowerUser"
          account_id     = "111111111111"
        }
      ]
    }
  }

  expect_failures = [
    aws_ssoadmin_account_assignment.this,
  ]
}
