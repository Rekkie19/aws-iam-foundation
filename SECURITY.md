# Security policy

## Reporting a vulnerability

Report vulnerabilities in this repository privately. Do not open a public GitHub issue, discussion, or pull request for a security report, and do not include exploit details in a public commit.

Use GitHub private vulnerability reporting:

<https://github.com/Rekkie19/aws-iam-foundation/security/advisories/new>

Include what you can of the following:

- A description of the issue and the impact you expect
- The path, workflow, or document involved
- Steps to reproduce, if you can do that without touching an account you do not own

Do not include live credentials, access keys, session tokens, passwords, Terraform state, or AWS account IDs. If a secret is part of the finding, describe where it was exposed and rotate it. Public history is not a safe place to delete a secret from; rotation is the remediation.

This is a personal portfolio project. There is no bug bounty. The maintainer aims to acknowledge a report within 7 days and will keep the details private until a fix or a reasoned dismissal is ready. Please give that process time before any public disclosure.

If the advisory page says private reporting is disabled, contact [@Rekkie19](https://github.com/Rekkie19) through GitHub and say that you have a security report. Wait for a private channel. Do not send proof-of-concept details in a public profile or issue.

AWS platform vulnerabilities belong to [AWS Security](https://aws.amazon.com/security/vulnerability-reporting/), not to this repository. This policy covers the Terraform, workflows, templates, and documentation published here.

The maintainer enables private vulnerability reporting under repository Settings, in the Security and quality section, on Advanced Security. See [Configuring private vulnerability reporting](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configure-for-a-repository).

## Supported versions

No release is tagged yet. Security fixes land on the default branch.

| Version | Supported |
| --- | --- |
| `main` | Yes |
| Tagged releases | None yet |
| Any other branch | No |

## Security principles

**No secrets in git.** Access keys, passwords, session tokens, private keys, Terraform state, and populated `*.tfvars` files do not belong in this repository, including in issues, pull requests, and CI logs. Example files use placeholders. `.terraform.lock.hcl` is a lock file, not a secret, and stays committed. Anything pushed to a public branch should be treated as public forever.

**OIDC only for automation.** GitHub Actions assumes an AWS role with OpenID Connect. The trust policy is limited to this repository and to the branch or GitHub Environment that is allowed to deploy. Workflows do not store static AWS credentials. Actions are pinned to a full commit SHA when workflows are added.

**Least privilege.** Permission sets and deploy roles grant only the actions the current milestone needs. SCPs add a deny guardrail on top of those grants. The production deploy role is assumed only from an approval-gated `production` environment. Human access goes through IAM Identity Center. The foundation does not create IAM users or long-lived keys.

**Root stays offline.** The management-account root user is protected by the [root lockdown checklist](docs/root-account-lockdown.md) and is not used for day-to-day administration or for Terraform applies.

**Detection is delegated.** Organization CloudTrail, GuardDuty, and IAM Access Analyzer are delegated to the Security account once that milestone lands. A billing alarm is part of the same baseline so unexpected spend is visible.

**State is protected.** The remote state backend is encrypted with a customer-managed key, versioned, and blocked from public access. Locking uses Terraform's S3 lockfile (`use_lockfile`). Plans are reviewed before apply.
