resource "aws_organizations_organization" "this" {
  feature_set = "ALL"

  # SCP is what milestone 5 will attach. Tag policies are enabled so a later
  # milestone can attach one; until a policy exists, nothing is enforced.
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
  ]

  # Trusted access only. This does not create a trail, a detector, an
  # analyzer, a configuration recorder, or an Identity Center instance.
  aws_service_access_principals = [
    "access-analyzer.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "sso.amazonaws.com",
  ]

  lifecycle {
    prevent_destroy = true
  }
}
