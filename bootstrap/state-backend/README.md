# State backend bootstrap

Root module for the remote state bucket. It is the one configuration that starts on local state: the bucket cannot store state until this module has created it.

The module creates:

- An S3 state bucket with versioning, SSE-KMS (customer-managed key, annual rotation, S3 Bucket Keys), Block Public Access, Bucket owner enforced, a TLS-only bucket policy, and a policy that denies uploads that omit the key or name a different key.
- A separate access-log bucket (SSE-S3, which S3 server access log delivery requires) with the same public-access and ownership controls.
- No DynamoDB table. Locking is Terraform's S3 lockfile (`use_lockfile = true`).

Apply it with an SSO session or an assumed-role admin profile. Do not use the root user. Do not create access keys.

## Apply once

```bash
export AWS_PROFILE=your-admin-profile
cd bootstrap/state-backend
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`. Set `name_prefix` so `<name_prefix>-tfstate` and `<name_prefix>-tfstate-logs` are globally unique, and set `aws_region`.

```bash
terraform init -backend=false
terraform plan -out=tfplan
terraform apply tfplan
```

Review the plan before `apply`. `terraform.tfvars`, `tfplan`, and `terraform.tfstate` are gitignored.

`kms_key_arn` and `backend_config_hcl` are sensitive outputs because the key ARN contains the account ID. Read them with `-raw` when you need the value, and do not paste them into git or a pull request.

## Migrate this module's state into the bucket

Optional, and worth doing so the bootstrap state is not left on disk.

```bash
umask 077
terraform output -raw backend_config_hcl > backend.hcl
cat > backend.tf <<'EOF'
terraform {
  backend "s3" {}
}
EOF

terraform init -migrate-state -backend-config=backend.hcl
terraform state pull >/dev/null
rm -f terraform.tfstate terraform.tfstate.backup tfplan
```

`backend.hcl` and `backend.tf` in this directory are gitignored. Keep `backend.hcl` in a password manager. After a fresh clone, recreate those two local files before the next plan.

`terraform state pull` reads the remote object. Run it after `init -migrate-state`. When it succeeds, the local state files are safe to delete.

If you skip migration, leave the local `terraform.tfstate` in this directory, keep it off git, and protect the workstation. The next apply of this module still uses that local state until you migrate.

## Later root modules

Copy `backend.hcl.example` to that module's `backend.hcl`, set `key` to that module's state path, and commit an empty backend block with the module when its milestone adds one:

```hcl
terraform {
  backend "s3" {}
}
```

Initialize with `terraform init -backend-config=backend.hcl`.

The KMS key policy allows cryptographic use only through S3, only for this state bucket's encryption context, and only for principals in this account. A future deploy role still needs identity-policy permission for `s3:ListBucket`, `s3:GetObject`, `s3:PutObject` on its state key, `s3:GetObject`, `s3:PutObject`, and `s3:DeleteObject` on the matching `.tflock` object, and `kms:Decrypt`, `kms:Encrypt`, and `kms:GenerateDataKey` on this key via S3.

## Recover the backend settings

Bucket names are `<name_prefix>-tfstate` and `<name_prefix>-tfstate-logs`. The key alias is `alias/<name_prefix>-tfstate`. With an admin profile:

```bash
aws kms describe-key --key-id alias/NAME_PREFIX-tfstate --region us-east-1
```

## Destroy

`prevent_destroy` is set on the buckets and the key. Destroy is a reviewed change that removes that lifecycle after state has moved elsewhere, then empties both buckets. Do not empty the state bucket while another root module still uses it.
