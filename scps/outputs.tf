output "policy_ids" {
  description = "IDs of the guardrail service control policies. These are policy ids, not account ids."
  value = {
    for name, id in local.guardrail_policy_ids : name => id
  }
}

output "attached_ou_ids" {
  description = "Organizational unit ids the guardrails attach to. The organization root is not a target."
  value       = var.attach_ou_ids
}

output "policy_character_counts" {
  description = "Character length of each SCP document, measured on the compact JSON this module submits."
  value = {
    leave_organization = length(local.leave_organization_document)
    security_services  = length(local.security_services_document)
    region_restriction = length(local.region_restriction_document)
    identity_baseline  = length(local.identity_baseline_document)
  }
}

output "scp_character_limit" {
  description = "Maximum SCP document size this module will apply."
  value       = local.scp_max_characters
}
