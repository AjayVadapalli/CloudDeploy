# Terraform guide

> **Cost warning:** Local validation does not create infrastructure. A genuine deployment creates AWS resources that may incur charges. Provision only for an intentional test session, watch current regional pricing, and follow the cleanup sequence immediately after testing. This project does not automatically apply or destroy Terraform.

## Local validation only

```powershell
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
```

`init -backend=false` and `validate` initialize local providers and check configuration. They do not provision resources. A normal `terraform init` may configure a backend, and `terraform apply` provisions infrastructure.

## Prepare the variables

Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and set the AWS region, GitHub owner/repository, and branch. `enable_rds` and `enable_alarms` default to `false`. Keep them disabled for this stateless API. RDS is optional, disconnected from the application, and can incur substantial charges if enabled.

There is no ECR-to-ECS dependency cycle: the ECR repository can be created independently. `image_uri` is a required Terraform input even for a targeted ECR operation, so the example tfvars includes a syntactically valid placeholder. After creating ECR and pushing the bootstrap image, replace the placeholder with that real image URI before provisioning ECS.

## One short deployment and CI/CD test session

These steps create billable resources. They are documentation for a later AWS test session; they have not been run as part of local verification.

1. From the `terraform` directory, create the ignored variables file, set the GitHub owner/repository and region, and keep the example placeholder `image_uri` for this ECR-only step. Then initialize Terraform, review a targeted plan, and create only the ECR repository.

   ```powershell
   cd terraform
   Copy-Item terraform.tfvars.example terraform.tfvars
   notepad terraform.tfvars
   terraform init
   terraform plan -target=aws_ecr_repository.api
   terraform apply -target=aws_ecr_repository.api
   $repository = terraform output -raw ecr_repository_url
   ```

2. From the repository root, build and push a bootstrap image. This requires Docker and AWS CLI login for the test account.

   ```powershell
   cd ..
   docker build -t ecs-spring-api:bootstrap .
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ($repository.Split('/')[0])
   docker tag ecs-spring-api:bootstrap "${repository}:bootstrap"
   docker push "${repository}:bootstrap"
   ```

3. Set `image_uri` in `terraform/terraform.tfvars` to `${repository}:bootstrap` (edit with `notepad terraform.tfvars`). From `terraform/`, run `terraform plan`, inspect the region and complete resource list, and run `terraform apply` only when you are ready to create the test stack. This creates the VPC, public subnets and routing, ALB, ECS Fargate service, security groups, IAM roles and OIDC provider, ECR repository, and CloudWatch log group. Optional RDS and alarms remain off.

   ```powershell
   terraform plan
   terraform apply
   ```

4. Set GitHub repository Actions variables from the Terraform outputs:

   | GitHub variable | Terraform value |
   |---|---|
   | `AWS_REGION` | `aws_region` used for this stack |
   | `AWS_DEPLOY_ROLE_ARN` | `github_actions_role_arn` |
   | `ECR_REPOSITORY` | `ecr_repository_url` |
   | `ECS_CLUSTER` | `ecs_cluster_name` |
   | `ECS_SERVICE` | `ecs_service_name` |
   | `ECS_TASK_DEFINITION` | `ecs_task_definition_family` |
   | `APP_URL` | `load_balancer_url` |

5. From GitHub Actions, select **Deploy to Amazon ECS**, choose `main`, and select **Run workflow**. Pushes to `main` do not deploy. The manual workflow builds and tests the app, builds and scans the image, authenticates with OIDC, pushes to ECR, registers a task-definition revision, updates ECS, waits for service stability, and checks `/health`. Then test `/`, `/api/hello`, `/health`, and `/api/info` at the ALB URL. This is a real AWS deployment and can incur charges.

The workflow updates the ECS service to a new task-definition revision but does not update Terraform state or `image_uri`. The ECS service has `ignore_changes = [task_definition]`, so later Terraform applies preserve the deployed revision rather than reverting it to the bootstrap image. Terraform continues to own the service and other infrastructure settings; application image deployments are owned by the manual GitHub workflow. If you change task-definition settings such as CPU, memory, or environment variables, make sure the updated revision is explicitly deployed to ECS because Terraform intentionally ignores that service field after creation.

## Clean up immediately after testing

1. Do not manually dispatch another deployment while cleaning up.
2. The ECR repository uses `force_delete=false`. Delete every tagged and untagged image in the project's ECR repository using the AWS console or AWS CLI before destroying Terraform. Terraform cannot delete a non-empty repository.
3. From the Terraform directory, inspect `terraform plan -destroy`. If the listed resources belong to this project and are safe to delete, run `terraform destroy`. This removes the ECS service/cluster, ALB and target group, VPC, subnets, routes, security groups, ECR repository, CloudWatch log group, IAM roles/policies, and the Terraform-managed GitHub OIDC provider.
4. RDS is off by default. If it was explicitly enabled, destruction with `skip_final_snapshot=true` permanently deletes its database. Review and delete any snapshots or Secrets Manager secret left behind.
5. If the GitHub OIDC provider existed before this project or is shared by other repositories, protect it from deletion. It is an account-level provider and may be needed elsewhere.
6. Verify in AWS that no project ALB, ECS service/tasks, ECR images/repository, CloudWatch log group, RDS instance/secret/snapshot, public IPv4 allocation, or project IAM role/provider remains. Billing reports may lag resource deletion.

Scaling ECS desired count to zero or stopping tasks does **not** remove the ALB, ECR images, CloudWatch logs, IAM roles, VPC networking, optional RDS, or other retained resources. Those resources can continue to incur charges until deleted. See [cost management](cost-management.md) for the resource-by-resource cost notes.

## State

Terraform state is local by default and may contain sensitive infrastructure values. Do not commit `.tfstate`, `.tfplan`, `.terraform/`, or real `.tfvars` files. A remote S3 backend is an optional team feature and is not configured here; creating and retaining a bucket adds another AWS resource and may incur charges.
