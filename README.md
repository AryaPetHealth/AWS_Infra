# AWS_Infra

Terraform for Arya's backend: Cognito (Sign in with Apple), a single-instance
Elastic Beanstalk app (FastAPI/Docker) that calls Textract directly, S3 →
SQS → SNS/APNs for async document processing, and RDS Postgres.

## Layout

- `bootstrap/` — one-time setup for the S3 bucket CI uses for remote state
  (native S3 locking — no DynamoDB table needed). Uses local state itself;
  apply this first, by itself.
- `modules/cognito` — user pool, Sign in with Apple federation, app client.
- `modules/storage` — S3 documents bucket, SQS processing queue (+ DLQ), SNS
  APNs platform application.
- `modules/database` — RDS Postgres, credentials in Secrets Manager.
- `modules/compute` — Elastic Beanstalk app/environment (single instance,
  rolling deploys — see note below) and its IAM role.
- `oidc.tf` — GitHub Actions OIDC IAM role, so CI can deploy without stored
  AWS access keys.

### State: local for you, S3 for CI

The root module has **no backend block checked in**, so a plain
`terraform init`/`plan` on your machine defaults to local state
(`terraform.tfstate`, gitignored) — good for iterating and verifying config
changes without touching shared state. The GitHub Actions workflow writes a
`backend_override.tf` at run time (pointing at the bucket from `bootstrap/`)
before it runs `init`, so CI runs are the only ones using the real S3-backed
state. If you ever want to apply from your machine against the real state,
write that same override file locally first (see step 4 below) — otherwise
your local runs and CI would silently diverge onto different state files.

### Why not immutable deployments?

AWS Elastic Beanstalk immutable deployments require a load-balanced
environment (a second instance spun up behind an ALB during rollout); they
aren't available on single-instance environments. To stay on a single
instance for cost, this uses EB's default in-place deploy instead — brief
downtime/restart per deploy, no ALB cost. If zero-downtime deploys become a
requirement later, switch `EnvironmentType` to `LoadBalanced` in
`modules/compute` and enable the immutable deployment policy.

## First-time setup

1. **Configure local AWS credentials** (`aws configure`, or `aws sso login`
   if you use IAM Identity Center) — needed for every step below.

2. **Bootstrap the state bucket** (run once):

   ```sh
   cd bootstrap
   terraform init
   terraform apply -var="state_bucket_name=<globally-unique-bucket-name>"
   cd ..
   ```

3. **Verify the root config locally** — no backend setup needed, this uses
   local state:

   ```sh
   terraform init
   terraform validate
   terraform plan   # will still need terraform.tfvars, see step 4
   ```

4. **Fill in secrets.** Copy `terraform.tfvars.example` to `terraform.tfvars`
   (gitignored) and fill in real values: Apple Sign in with Apple
   credentials, APNs token-signing key, and a unique S3 bucket name for
   documents.

5. **Apply once locally** (still against local state) so the GitHub Actions
   OIDC role (`oidc.tf`) exists:

   ```sh
   terraform apply
   ```

6. **Wire up CI.** In the repo's GitHub settings:
   - Add repo **variables**: `AWS_ROLE_ARN` = the `github_actions_role_arn`
     output from step 5, and `TF_STATE_BUCKET` = the bucket name from
     step 2.
   - Add repo **secrets** for everything sensitive in `terraform.tfvars`:
     `APPLE_SERVICES_ID`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`,
     `APPLE_PRIVATE_KEY`, `COGNITO_CALLBACK_URLS`, `COGNITO_LOGOUT_URLS`,
     `APNS_SIGNING_KEY`, `APNS_SIGNING_KEY_ID`, `APNS_TEAM_ID`,
     `APNS_BUNDLE_ID`, `DOCUMENTS_BUCKET_NAME` (list-valued vars as JSON,
     e.g. `["arya://callback"]`).

   From here, `.github/workflows/terraform.yml` runs `plan` on pull requests
   and `apply` on pushes to `main`, using S3 remote state and OIDC — no
   stored AWS keys.

   Note: after step 5, the *real* infrastructure exists in your local state
   file, not in S3. Either migrate that local state into the S3 backend
   (`terraform init -migrate-state` after adding a matching backend block)
   before merging, or let the first CI apply reconcile from scratch — check
   which you want before pushing to `main`.
