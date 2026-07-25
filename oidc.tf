# Lets GitHub Actions assume an IAM role via short-lived OIDC tokens instead
# of storing long-lived AWS access keys as repo secrets — the GitHub Actions
# equivalent of an Azure DevOps "service connection".
#
# Bootstrapping note: the OIDC provider itself must already exist in the
# account (created once, out of band, with real human AWS credentials)
# before CI can use it. Its ARN is deterministic (account ID + fixed URL),
# so it's built as a plain string below instead of looked up via Terraform
# — no data source, no extra IAM permission needed to read it. Managing it
# as a resource here would also conflict across the separate dev/prod
# state files, since only one provider can exist per URL per account.

data "aws_caller_identity" "current" {}

locals {
  github_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_actions_terraform" {
  name = "${var.project_name}-${var.environment}-github-actions-terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.github_oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # GitHub's sub claim embeds immutable numeric IDs alongside the
          # org/repo names (e.g. "repo:Org@123/Repo@456:ref:...") to stop a
          # renamed/reclaimed org or repo from inheriting old trust — so
          # this can't be a plain "repo:OWNER/REPO:*" match. Wildcard the
          # IDs since they're opaque and not worth pinning by hand.
          "token.actions.githubusercontent.com:sub" = "repo:${split("/", var.github_repo)[0]}@*/${split("/", var.github_repo)[1]}@*:*"
        }
      }
    }]
  })
}

# PowerUserAccess covers everything Terraform manages here (Cognito, EB, S3,
# SQS, SNS, RDS, Secrets Manager, EC2 security groups) except IAM, which
# PowerUserAccess deliberately excludes.
resource "aws_iam_role_policy_attachment" "github_actions_power_user" {
  role       = aws_iam_role.github_actions_terraform.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Narrow IAM permissions, scoped to only the roles/instance profiles this
# project creates (the EB EC2 role), so CI can't touch unrelated IAM state.
resource "aws_iam_role_policy" "github_actions_iam_scoped" {
  name = "${var.project_name}-${var.environment}-github-actions-iam"
  role = aws_iam_role.github_actions_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "ManageAppIamResources"
      Effect = "Allow"
      Action = [
        "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:TagRole",
        "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy",
        "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
        "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:PassRole",
        "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile", "iam:GetInstanceProfile",
        "iam:TagInstanceProfile", "iam:UntagInstanceProfile",
        "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",
      ]
      Resource = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.project_name}-*",
      ]
    }]
  })
}
