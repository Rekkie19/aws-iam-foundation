# Every guardrail attaches to the same OU set. The set is the rollout
# control: workloads_dev first, then Security and Workloads-Prod.
#
# This module never attaches to the organization root. An SCP on the root
# would hit every member account on the next apply and skip that rollout.
# SCPs do not apply to the management account even when they are attached
# to the root; validation still rejects root ids and account ids.
#
# The AWS managed FullAWSAccess policy stays attached to the root. This
# module does not detach it. Detaching it denies every action that another
# SCP does not explicitly allow, which these deny-only policies do not do.

locals {
  guardrail_policy_ids = {
    leave_organization = aws_organizations_policy.leave_organization.id
    security_services  = aws_organizations_policy.security_services.id
    region_restriction = aws_organizations_policy.region_restriction.id
    identity_baseline  = aws_organizations_policy.identity_baseline.id
  }

  guardrail_attachments = {
    for pair in setproduct(keys(local.guardrail_policy_ids), keys(var.attach_ou_ids)) :
    "${pair[0]}/${pair[1]}" => {
      policy_id = local.guardrail_policy_ids[pair[0]]
      target_id = var.attach_ou_ids[pair[1]]
    }
  }
}

resource "aws_organizations_policy_attachment" "guardrail" {
  for_each = local.guardrail_attachments

  policy_id = each.value.policy_id
  target_id = each.value.target_id
}
