locals {
  leave_organization_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyLeaveOrganization"
        Effect   = "Deny"
        Action   = ["organizations:LeaveOrganization"]
        Resource = "*"
      }
    ]
  })

  # Exempt principals may still change these services. A stolen exempt role
  # can disable a detector or a trail. Keep the list to break-glass and to
  # the automation role that milestone 10 will use from a member account.
  # Applies from the management account are not filtered by any SCP.
  security_services_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyDisableSecurityServices"
        Effect = "Deny"
        Action = [
          "access-analyzer:DeleteAnalyzer",
          "cloudtrail:DeleteEventDataStore",
          "cloudtrail:DeleteTrail",
          "cloudtrail:PutEventSelectors",
          "cloudtrail:PutInsightSelectors",
          "cloudtrail:StopEventDataStoreIngestion",
          "cloudtrail:StopLogging",
          "cloudtrail:UpdateEventDataStore",
          "cloudtrail:UpdateTrail",
          "config:DeleteConfigRule",
          "config:DeleteConfigurationAggregator",
          "config:DeleteConfigurationRecorder",
          "config:DeleteDeliveryChannel",
          "config:DeleteOrganizationConfigRule",
          "config:DeleteOrganizationConformancePack",
          "config:DeleteRetentionConfiguration",
          "config:PutConfigurationRecorder",
          "config:StopConfigurationRecorder",
          "guardduty:DeleteDetector",
          "guardduty:DeleteMembers",
          "guardduty:DeletePublishingDestination",
          "guardduty:DisableOrganizationAdminAccount",
          "guardduty:DisassociateFromMasterAccount",
          "guardduty:DisassociateMembers",
          "guardduty:StopMonitoringMembers",
          "guardduty:UpdateDetector",
          "guardduty:UpdateOrganizationConfiguration",
        ]
        Resource = "*"
        Condition = {
          ArnNotLike = {
            "aws:PrincipalArn" = var.exempt_principal_arns
          }
        }
      }
    ]
  })

  region_restriction_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyOutsideAllowedRegions"
        Effect    = "Deny"
        NotAction = local.global_service_exemptions
        Resource  = "*"
        Condition = {
          ArnNotLike = {
            "aws:PrincipalArn" = var.exempt_principal_arns
          }
          StringNotEquals = {
            "aws:RequestedRegion" = var.allowed_regions
          }
        }
      }
    ]
  })

  identity_baseline_document = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "DenyCreateIamUsers"
          Effect = "Deny"
          Action = [
            "iam:CreateLoginProfile",
            "iam:CreateUser",
          ]
          Resource = "*"
        },
        {
          Sid    = "DenyCreateAccessKeys"
          Effect = "Deny"
          Action = [
            "iam:CreateAccessKey",
          ]
          Resource = "*"
        },
        {
          # Deny every action when the caller is the account root. The
          # condition is the root principal, so a role exemption does not
          # apply. Member-account root API calls stop while this policy is
          # attached. The management account is unaffected because SCPs do
          # not apply there.
          Sid      = "DenyRootUser"
          Effect   = "Deny"
          Action   = ["*"]
          Resource = "*"
          Condition = {
            ArnLike = {
              "aws:PrincipalArn" = ["arn:aws:iam::*:root"]
            }
          }
        },
        {
          Sid    = "DenyPublicCannedAcls"
          Effect = "Deny"
          Action = [
            "s3:PutBucketAcl",
            "s3:PutObjectAcl",
          ]
          Resource = "*"
          Condition = {
            StringEquals = {
              "s3:x-amz-acl" = [
                "authenticated-read",
                "public-read",
                "public-read-write",
              ]
            }
          }
        },
      ],
      [
        for header in local.s3_public_grant_headers : {
          Sid    = header.sid
          Effect = "Deny"
          Action = [
            "s3:PutBucketAcl",
            "s3:PutObjectAcl",
          ]
          Resource = "*"
          Condition = {
            StringLike = {
              (header.key) = local.s3_public_grant_patterns
            }
          }
        }
      ],
    )
  })
}

resource "aws_organizations_policy" "leave_organization" {
  name        = "foundation-deny-leave-organization"
  description = "Deny organizations:LeaveOrganization. No principal is exempt."
  type        = "SERVICE_CONTROL_POLICY"
  content     = local.leave_organization_document

  lifecycle {
    precondition {
      condition     = length(local.leave_organization_document) <= local.scp_max_characters
      error_message = "foundation-deny-leave-organization is ${length(local.leave_organization_document)} characters. The module limit is ${local.scp_max_characters}."
    }
  }
}

resource "aws_organizations_policy" "security_services" {
  name        = "foundation-deny-disable-security-services"
  description = "Deny disabling or deleting CloudTrail, GuardDuty, AWS Config, and IAM Access Analyzer, except exempt_principal_arns."
  type        = "SERVICE_CONTROL_POLICY"
  content     = local.security_services_document

  lifecycle {
    precondition {
      condition     = length(local.security_services_document) <= local.scp_max_characters
      error_message = "foundation-deny-disable-security-services is ${length(local.security_services_document)} characters. The module limit is ${local.scp_max_characters}."
    }
  }
}

resource "aws_organizations_policy" "region_restriction" {
  name        = "foundation-region-restriction"
  description = "Deny calls outside allowed_regions, with global-service and exempt-principal exceptions."
  type        = "SERVICE_CONTROL_POLICY"
  content     = local.region_restriction_document

  lifecycle {
    precondition {
      condition     = length(local.region_restriction_document) <= local.scp_max_characters
      error_message = "foundation-region-restriction is ${length(local.region_restriction_document)} characters. The module limit is ${local.scp_max_characters}."
    }
  }
}

resource "aws_organizations_policy" "identity_baseline" {
  name        = "foundation-identity-baseline"
  description = "Deny IAM users, access keys, member-account root actions, and public S3 ACLs. No principal is exempt."
  type        = "SERVICE_CONTROL_POLICY"
  content     = local.identity_baseline_document

  lifecycle {
    precondition {
      condition     = length(local.identity_baseline_document) <= local.scp_max_characters
      error_message = "foundation-identity-baseline is ${length(local.identity_baseline_document)} characters. The module limit is ${local.scp_max_characters}."
    }
  }
}
