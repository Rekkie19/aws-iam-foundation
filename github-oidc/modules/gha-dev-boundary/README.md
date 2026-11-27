# GhaDevBoundary

Customer-managed permissions boundary for `gha-dev-plan` and `gha-dev-deploy`.

The [`github-oidc`](../..) root calls this module in the dev account. Apply that root. Do not apply this directory on its own: it has no provider and no backend.

The document is [`boundary/gha-dev-boundary.json`](../../boundary/gha-dev-boundary.json). `Allow *` is the ceiling a boundary needs. The deny statements are the control: IAM users and access keys, organization changes, disabling CloudTrail, GuardDuty, AWS Config, and IAM Access Analyzer, and edits to this policy or to a role that does not wear it. The ARN in the document uses an account wildcard, not an account ID.

The policy name must stay `GhaDevBoundary` unless the JSON and `boundary_policy_name` change together. A precondition fails the plan when they diverge.
