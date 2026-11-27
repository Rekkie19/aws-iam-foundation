# Contributing

Install the hooks once per clone, before the first commit. They run `terraform fmt`, `terraform validate`, TFLint, Gitleaks, Checkov, and actionlint, plus whitespace and secret-file hygiene.

## Tools

Put these on `PATH`:

- [pre-commit](https://pre-commit.com/) 3.2 or later
- Terraform 1.10 or later (the S3 lockfile needs it)
- [TFLint](https://github.com/terraform-linters/tflint)
- [Gitleaks](https://github.com/gitleaks/gitleaks) is built by the hook from tag `v8.30.1`. That build needs Go.
- [actionlint](https://github.com/rhysd/actionlint) is built by the hook from tag `v1.7.12`. That build needs Go.
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

## Pull request CI

[`.github/workflows/pr-ci.yml`](.github/workflows/pr-ci.yml) runs on `pull_request` to `main` and on `push` to `main`. It does not run on `pull_request_target`.

`pull_request` checks out the merge commit and gives the job a read-only token. Secrets are not available. `pull_request_target` would run in the base repository with a token that can write. A step that checked out the pull request head would then run fork code with that token. This workflow installs tools and executes the repository, so that event is rejected. ADR-011 records the choice.

A pull request from a fork runs the same jobs. GitHub may hold the first run from a new fork until a maintainer approves Actions. The workflow has no repository secrets and no AWS role, so the approved run still cannot deploy. The Checkov SARIF upload runs only when the head repository is this repository, because a fork token cannot be granted `security-events: write`. A Checkov finding still fails the job.

The workflow does not assume `gha-dev-plan` or `gha-dev-deploy`. Those roles are for a later apply workflow. This file is fmt, validate, TFLint, `terraform test`, Gitleaks, Checkov, Trivy, actionlint, and zizmor.

After the workflow is on `main`, require these check names in branch protection. The names are the job names, including the matrix label:

- `fmt`
- `terraform (state-backend)`
- `terraform (organization)`
- `terraform (scps)`
- `terraform (identity-center)`
- `terraform (dev-power-user-boundary)`
- `terraform (github-oidc)`
- `terraform (gha-dev-boundary)`
- `gitleaks`
- `checkov`
- `trivy`
- `actionlint`
- `zizmor`

The owner sets that protection by hand. Nothing in this repository turns it on.
