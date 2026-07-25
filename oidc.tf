# Lets GitHub Actions assume an IAM role via short-lived OIDC tokens instead
# of storing long-lived AWS access keys as repo secrets — the GitHub Actions
# equivalent of an Azure DevOps "service connection".
#
# Bootstrapping note: the OIDC provider AND this role/its policies must
# already exist in the account (created once, out of band, with real human
# AWS credentials) before CI can use them. None of it is managed here as a
# Terraform resource — CI managing the very role/permissions it runs as
# is a self-referential bootstrap problem (a reset or reimport of state
# makes Terraform think these don't exist yet and try to recreate them,
# which fails since they already do), and it also can't safely be shared
# across the separate dev/prod state files. ARNs are deterministic
# (account ID + fixed name), so they're built as plain strings instead.
#
# The role's assume-role policy trusts the OIDC provider for
# sts:AssumeRoleWithWebIdentity, scoped to this repo via the
# token.actions.githubusercontent.com:sub claim
# (repo:${var.github_repo}@*:*). It has PowerUserAccess (covers Cognito,
# EB, S3, SQS, SNS, RDS, Secrets Manager, EC2 security groups) plus a
# narrow inline policy for IAM actions PowerUserAccess excludes, scoped to
# roles/instance profiles named "${var.project_name}-*": CreateRole,
# DeleteRole, GetRole, TagRole, PutRolePolicy, DeleteRolePolicy,
# GetRolePolicy, ListRolePolicies, ListAttachedRolePolicies,
# AttachRolePolicy, DetachRolePolicy, PassRole, CreateInstanceProfile,
# DeleteInstanceProfile, GetInstanceProfile, TagInstanceProfile,
# UntagInstanceProfile, AddRoleToInstanceProfile,
# RemoveRoleFromInstanceProfile.

data "aws_caller_identity" "current" {}

locals {
  github_actions_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.environment}-github-actions-terraform"
}
