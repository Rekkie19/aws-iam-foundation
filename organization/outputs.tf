output "organization_id" {
  description = "ID of the organization."
  value       = aws_organizations_organization.this.id
}

output "organization_root_id" {
  description = "ID of the organization root. The management account stays in the root."
  value       = aws_organizations_organization.this.roots[0].id
}

output "organizational_unit_ids" {
  description = "IDs of the Security, Workloads-Dev, and Workloads-Prod organizational units."
  value = {
    security       = aws_organizations_organizational_unit.security.id
    workloads_dev  = aws_organizations_organizational_unit.workloads_dev.id
    workloads_prod = aws_organizations_organizational_unit.workloads_prod.id
  }
}

output "account_ids" {
  description = "IDs of the management account and the Security, Dev, and Prod member accounts."
  value = {
    management = aws_organizations_organization.this.master_account_id
    # The email variable is sensitive, which marks every attribute of the
    # account resource. The account ID is not the email.
    security = nonsensitive(aws_organizations_account.security.id)
    dev      = nonsensitive(aws_organizations_account.dev.id)
    prod     = nonsensitive(aws_organizations_account.prod.id)
  }
}
