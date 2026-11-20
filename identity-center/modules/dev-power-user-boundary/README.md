# DevPowerUser boundary

Apply this module once in each account that will receive the `DevPowerUser` permission set. Identity Center looks the policy up by name in the target account. The management account does not need it unless you assign DevPowerUser there, and this foundation rejects that assignment.

The policy document is [`../../boundary/dev-power-user-boundary.json`](../../boundary/dev-power-user-boundary.json). It allows the actions a boundary must allow, then denies IAM users and access keys, organization changes, disabling CloudTrail, GuardDuty, AWS Config, and IAM Access Analyzer, and edits to this policy or to a role that lacks this boundary.

```bash
terraform init
terraform apply -var='aws_region=us-east-1'
```

Use credentials for that target account. Do not use the root user. The name must match `dev_power_user_boundary_name` in the identity-center root.
