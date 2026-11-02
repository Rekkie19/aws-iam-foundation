# One account at a time. Parallel CreateAccount calls against a new
# organization fail with ConcurrentModificationException while the
# organization is still finalizing.

resource "aws_organizations_account" "security" {
  name                       = "Security"
  email                      = var.account_emails.security
  parent_id                  = aws_organizations_organizational_unit.security.id
  role_name                  = "OrganizationAccountAccessRole"
  iam_user_access_to_billing = "DENY"
  close_on_deletion          = false

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }

  lifecycle {
    prevent_destroy = true

    # Both arguments are ForceNew, and DescribeAccount does not return them.
    # Create still sends DENY and OrganizationAccountAccessRole. Ignoring them
    # stops a later plan from replacing the account to reconcile a value AWS
    # will not read back.
    ignore_changes = [
      role_name,
      iam_user_access_to_billing,
    ]
  }
}

resource "aws_organizations_account" "dev" {
  name                       = "Dev"
  email                      = var.account_emails.dev
  parent_id                  = aws_organizations_organizational_unit.workloads_dev.id
  role_name                  = "OrganizationAccountAccessRole"
  iam_user_access_to_billing = "DENY"
  close_on_deletion          = false

  depends_on = [aws_organizations_account.security]

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      role_name,
      iam_user_access_to_billing,
    ]
  }
}

resource "aws_organizations_account" "prod" {
  name                       = "Prod"
  email                      = var.account_emails.prod
  parent_id                  = aws_organizations_organizational_unit.workloads_prod.id
  role_name                  = "OrganizationAccountAccessRole"
  iam_user_access_to_billing = "DENY"
  close_on_deletion          = false

  depends_on = [aws_organizations_account.dev]

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      role_name,
      iam_user_access_to_billing,
    ]
  }
}
