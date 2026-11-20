# The instance URL is the GitHub Actions OIDC issuer.
# AWS secures this issuer with its trusted CA library. thumbprint_list is
# optional in the current AWS provider and is not a security control for
# token.actions.githubusercontent.com. Leave var.thumbprint_list null unless
# a fetched thumbprint produces a perpetual diff you want to pin.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.thumbprint_list

  tags = {
    IdentityProvider = "github-actions"
  }
}
