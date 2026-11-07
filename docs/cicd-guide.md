# CI/CD and GitHub OIDC

## CI workflow

`.github/workflows/ci.yml` checks out the code, installs Eclipse Temurin Java 21, runs Maven verification (including unit and context tests), then builds the Docker image. It runs on pushes and pull requests and requires no AWS credentials.

## Deployment workflow

`.github/workflows/deploy.yml` runs only by manual `workflow_dispatch` from `main`; pushes do not deploy. It validates required repository variables, builds/tests, builds an image tagged with commit SHA, workflow run ID, and rerun attempt, scans HIGH/CRITICAL vulnerabilities with Trivy 0.35.0, assumes the deployment role with OIDC, pushes to ECR, registers an ECS task-definition revision, updates the service, waits for stability, and checks the ALB health URL. The unique tag works with ECR's immutable-tag setting and permits reruns. A failed scan stops deployment.

## OIDC setup

Terraform creates an IAM OIDC provider for `token.actions.githubusercontent.com` and an IAM role trust policy restricted to the exact `OWNER/REPOSITORY` and `main` branch. The workflow requests `id-token: write`; AWS returns temporary role credentials, so no AWS access key is stored in GitHub.

## First setup

1. Follow the ECR bootstrap and full infrastructure sequence in the Terraform guide. Terraform creates only the ECR repository first so you can push an initial image before creating the ECS service.
2. In GitHub repository Settings → Secrets and variables → Actions → Variables, create `AWS_REGION`, `AWS_DEPLOY_ROLE_ARN`, `ECR_REPOSITORY`, `ECS_CLUSTER`, `ECS_SERVICE`, `ECS_TASK_DEFINITION`, and `APP_URL` from Terraform outputs. `ECS_TASK_DEFINITION` is the task-definition family (currently `ecs-spring-api`), separate from the ECS service name.
3. Confirm GitHub Actions is enabled. From the Actions tab, choose **Deploy to Amazon ECS**, select `main`, and click **Run workflow**. Pushes to `main` do not trigger deployment.
4. If the repo uses a GitHub environment or custom OIDC subject template, update the Terraform trust policy to match that subject. The included workflow uses branch-based subject claims.

Third-party actions are pinned to full commit SHAs; comments identify their upstream releases. Verify pins when upgrading. The manually dispatched workflow can push images and update ECS, so it is a real AWS deployment and may incur charges. Trigger it only after provisioning and immediately destroy the stack once live verification is complete.
