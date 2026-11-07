# Architecture

## Request path

An internet user sends HTTP to the public ALB. The ALB forwards to port 8080 on the ECS Fargate service and checks `/health`. The task security group only permits ingress from the ALB security group. Tasks use public subnets/public IPs by default to avoid NAT and endpoint charges. The API is stateless; optional RDS resources are disabled by default and are not connected to it.

## Deployment path

GitHub Actions builds and scans a commit-tagged image, obtains temporary AWS credentials through OIDC, pushes to ECR, registers a new ECS task definition using that image, updates the service, waits for stability, then calls `/health`. Terraform owns infrastructure and the initial task definition. The ECS service ignores later task-definition changes so Terraform will not revert the service to its bootstrap revision after a GitHub Actions deployment.

## Cost/security tradeoff

Private tasks are a better network boundary for production, but need egress to ECR and CloudWatch. A NAT Gateway is simplest and can be expensive; VPC interface endpoints also have hourly and data charges. This project uses public tasks with no direct inbound rule to avoid those additional networking resources. This setup is for learning and should be reviewed before production use.
