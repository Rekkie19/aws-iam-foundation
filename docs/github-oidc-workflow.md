# GitHub Actions workflow sketch

This is documentation for the dev plan and deploy roles. It is not a workflow. Milestone 8 adds the real file under `.github/workflows/`. Do not copy this into `.github/workflows/` until that milestone.

The role ARN is a GitHub Actions **variable**, not a secret. Do not hardcode an account ID in the workflow. Set `AWS_DEV_PLAN_ROLE_ARN`, `AWS_DEV_DEPLOY_ROLE_ARN`, and `AWS_REGION` in the repository variables after apply, from `terraform output -raw`.

`aws-actions/configure-aws-credentials` is pinned to the v6.3.0 commit. Dependabot can bump that pin when the workflow exists. `permissions` must grant `id-token: write` or GitHub will not mint the OIDC token. `contents: read` is enough to check out the ref.

`pull_request` assumes `gha-dev-plan`. A push to `main` assumes `gha-dev-deploy`. Do not switch the plan job to `pull_request_target`. That event runs in the base repository and can mint an OIDC token for a fork's code.

```yaml
name: dev

on:
  pull_request:
  push:
    branches:
      - main

permissions:
  id-token: write
  contents: read

jobs:
  plan:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
        with:
          role-to-assume: ${{ vars.AWS_DEV_PLAN_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}
          role-session-name: gha-dev-plan

  deploy:
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
        with:
          role-to-assume: ${{ vars.AWS_DEV_DEPLOY_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}
          role-session-name: gha-dev-deploy
```

For this repository, `example-org` and `example-repo` in the Terraform example become the GitHub owner and `aws-iam-foundation`. The workflow still reads the role ARN from a variable, so the owner name is not written into the workflow.
