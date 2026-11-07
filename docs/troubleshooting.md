# Troubleshooting and validation

## Local checks

```bash
mvn --batch-mode clean verify
docker build -t ecs-spring-api:local .
docker run --rm -p 8080:8080 ecs-spring-api:local
curl -i http://localhost:8080/health
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
```

Validate workflows using `actionlint` if installed. Terraform initialization may download provider plugins when using `-backend=false`; this does not use AWS credentials. The deployment workflow and Terraform apply/destroy commands are real AWS operations, not local validation; use the documented test-session and cleanup sequence when intentionally deploying.

## AWS diagnosis

- **Tasks fail to start:** inspect ECS service events and task stopped reason. Check image URI/tag, task execution role, ECR permissions, and CloudWatch log group.
- **ALB returns 503:** target health is failing. Check `/health`, port 8080 mapping, target group port, security group path, and ECS task logs.
- **OIDC AccessDenied:** compare repository owner/name and branch with the IAM `sub` trust condition; ensure workflow declares `id-token: write` and uses the role ARN output.
- **Terraform rejects duplicate provider:** import the account's existing GitHub OIDC provider or adapt the config to reuse it.

CloudWatch log group: `/ecs/ecs-spring-api`. ECS service events and task stopped reasons are usually the fastest first checks.
