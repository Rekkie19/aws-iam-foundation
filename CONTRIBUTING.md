# Contributing

Install the hooks once per clone, before the first commit. They run `terraform fmt`, `terraform validate`, TFLint, Gitleaks, and Checkov, plus whitespace and secret-file hygiene.

## Tools

Put these on `PATH`:

- [pre-commit](https://pre-commit.com/) 3.2 or later
- Terraform 1.10 or later (the S3 lockfile needs it)
- [TFLint](https://github.com/terraform-linters/tflint)
- [Gitleaks](https://github.com/gitleaks/gitleaks) is built by the hook from tag `v8.30.1`. That build needs Go.
- Checkov is installed by the hook at tag `3.4.0` into its own environment. A local Checkov install is only needed if you want to run it outside pre-commit.

The TFLint AWS plugin is not installed by the TFLint release itself. The first `terraform_tflint` run executes `tflint --init` against [`.tflint.hcl`](.tflint.hcl), which pins `tflint-ruleset-aws` `0.50.0`.

```bash
pipx install pre-commit
# or: python3 -m pip install --user pre-commit
```

Install Terraform and TFLint from their release pages. Do not point the tools at the root user, and do not create access keys for a hook run. `terraform validate` uses `-backend=false` and does not need AWS credentials.

## Enable the hooks

From the repository root:

```bash
pre-commit install
pre-commit run --all-files
```

`pre-commit install` runs the hooks on every commit. `pre-commit run --all-files` runs them once against the tree. The first run downloads the pinned hook environments, including the AWS TFLint plugin, and can take a few minutes.

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/). Pull requests use the checklist in [`.github/pull_request_template.md`](.github/pull_request_template.md). Report vulnerabilities through [SECURITY.md](SECURITY.md), not through a commit or a public issue.
