# GitHub Actions IAM Role – CloudFormation Template

This CloudFormation template creates the IAM role that allows GitHub Actions to securely authenticate to AWS and deploy the Lumiatech application to Amazon ECS — without storing long-lived AWS credentials in GitHub secrets.

## How It Works

Authentication is done via **OpenID Connect (OIDC)**. When a GitHub Actions workflow runs, GitHub issues a short-lived token. AWS verifies this token against the GitHub OIDC provider and grants temporary credentials by assuming the IAM role. No `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` is needed.

```
GitHub Actions Workflow
        │
        │  presents OIDC token
        ▼
GitHub OIDC Provider (token.actions.githubusercontent.com)
        │
        │  verified by AWS IAM
        ▼
IAM Role (lumiatech-github-actions-ecs-role)
        │
        ├── Push image → Amazon ECR
        ├── Register task definition → Amazon ECS
        ├── Update ECS service → Amazon ECS
        └── Read logs → Amazon CloudWatch
```

## Resources Created

| Resource | Name | Purpose |
|---|---|---|
| `AWS::IAM::OIDCProvider` | GitHub OIDC Provider | Trusts GitHub-issued tokens (conditional) |
| `AWS::IAM::Role` | `lumiatech-github-actions-ecs-role` | Role assumed by GitHub Actions |

## IAM Policies Attached to the Role

| Policy | Permissions |
|---|---|
| `ECRAccess` | Login, push, pull, and describe images in ECR |
| `ECSDeploymentAccess` | Register task definitions, update and describe ECS services |
| `IAMPassRole` | Pass roles to `ecs-tasks.amazonaws.com` only |
| `CloudWatchLogsAccess` | Read CloudWatch log groups and streams for deployment visibility |

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `GitHubOrg` | `ndzenyuy` | Your GitHub username or organization |
| `GitHubRepo` | `project-3-deploy-to-ecs` | Repository name. Use `*` to allow all repos in the org |
| `CreateOIDCProvider` | `false` | Set to `true` only if no GitHub OIDC provider exists in your AWS account |

> **Important:** Only one GitHub OIDC provider can exist per AWS account. If you have already deployed another stack that created one, leave `CreateOIDCProvider` as `false`.

## Deployment

### Check if OIDC Provider Already Exists

Before deploying, run this command to check:

```bash
aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[*].Arn"
```

If `arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com` appears in the output, the provider already exists — keep `CreateOIDCProvider=false`.

---

### First-Time Deploy (no OIDC provider exists)

```bash
aws cloudformation deploy \
  --template-file cloudformation/github-actions-role.yml \
  --stack-name lumiatech-github-actions-role \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      CreateOIDCProvider=true \
      GitHubOrg=ndzenyuy \
      GitHubRepo=project-3-deploy-to-ecs
```

### Deploy When OIDC Provider Already Exists

```bash
aws cloudformation deploy \
  --template-file cloudformation/github-actions-role.yml \
  --stack-name lumiatech-github-actions-role \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      GitHubOrg=ndzenyuy \
      GitHubRepo=project-3-deploy-to-ecs
```

---

## After Deployment – Configure GitHub

### 1. Get the Role ARN from stack outputs

```bash
aws cloudformation describe-stacks \
  --stack-name lumiatech-github-actions-role \
  --query "Stacks[0].Outputs[?OutputKey=='GitHubActionsRoleArn'].OutputValue" \
  --output text
```

### 2. Add the Role ARN as a GitHub Secret

Go to your GitHub repository:

```
Settings → Secrets and variables → Actions → New repository secret
```

| Secret Name | Value |
|---|---|
| `AWS_GITHUB_ROLE` | `arn:aws:iam::<account-id>:role/lumiatech-github-actions-ecs-role` |

### 3. Reference the secret in your workflow

The `.github/workflows/deploy.yml` already uses this secret:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_GITHUB_ROLE }}
    aws-region: us-east-1
```

## Updating the Stack

To update parameters (e.g. change the repo name), re-run the deploy command with the new values. CloudFormation will update only what has changed.

## Deleting the Stack

```bash
aws cloudformation delete-stack --stack-name lumiatech-github-actions-role
```

> If `CreateOIDCProvider=true` was used, the OIDC provider will also be deleted. This may affect other stacks in the same account that rely on it.
