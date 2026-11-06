locals {
  # Ceiling enforced by this module. In May 2026 AWS raised the service quota
  # to 10240 characters and 10 directly attached SCPs per root, OU, or account.
  # Documents here stay at or under the previous 5120-character ceiling so each
  # guardrail stays reviewable and still fits an organization on the old quota.
  # Organizations stores the content string as submitted. jsonencode is compact,
  # and that compact string is what length() measures.
  scp_max_characters = 5120

  # APIs that are global, or that the console calls without a workload region.
  # CloudTrail, GuardDuty, AWS Config, KMS, and bucket-level S3 stay off this
  # list so the region guardrail still covers them. organizations:* is here
  # because the organization APIs are global; LeaveOrganization is denied by
  # a separate statement, and an explicit Deny in that policy still wins.
  global_service_exemptions = [
    "artifact:*",
    "aws-portal:*",
    "budgets:*",
    "ce:*",
    "cloudfront:*",
    "cur:*",
    "ec2:DescribeAvailabilityZones",
    "ec2:DescribeRegions",
    "health:*",
    "iam:*",
    "organizations:*",
    "pricing:*",
    "route53:*",
    "route53-recovery-cluster:*",
    "route53-recovery-control-config:*",
    "route53-recovery-readiness:*",
    "route53domains:*",
    "s3:GetAccountPublicAccessBlock",
    "s3:GetBucketLocation",
    "s3:ListAllMyBuckets",
    "shield:*",
    "sts:*",
    "support:*",
    "supportplans:*",
    "trustedadvisor:*",
    "waf:*",
    "wafv2:*",
  ]

  # DeletePublicAccessBlock uses s3:PutBucketPublicAccessBlock, the same
  # action that turns the block on. An SCP cannot see the four booleans, so
  # denying that action would also block enabling Block Public Access.
  # Canned public ACLs and public grant headers are the writes that can be
  # denied without blocking the block itself.
  s3_public_grant_headers = [
    { sid = "DenyPublicGrantRead", key = "s3:x-amz-grant-read" },
    { sid = "DenyPublicGrantWrite", key = "s3:x-amz-grant-write" },
    { sid = "DenyPublicGrantReadAcp", key = "s3:x-amz-grant-read-acp" },
    { sid = "DenyPublicGrantWriteAcp", key = "s3:x-amz-grant-write-acp" },
    { sid = "DenyPublicGrantFullControl", key = "s3:x-amz-grant-full-control" },
  ]

  s3_public_grant_patterns = [
    "*http://acs.amazonaws.com/groups/global/AllUsers*",
    "*http://acs.amazonaws.com/groups/global/AuthenticatedUsers*",
  ]
}
