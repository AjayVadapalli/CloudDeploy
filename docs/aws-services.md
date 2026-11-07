# AWS services

- **VPC/subnets/routes:** isolate resources; the Internet Gateway provides public-subnet routes. Database subnets have no internet route.
- **Security groups:** ALB permits public HTTP; task ingress is ALB-only.
- **ECR:** stores immutable image tags and scans on push. Image storage and scanning can cost money.
- **ECS Fargate:** runs the container without managing EC2 hosts. Desired count is one by default and billed while running.
- **ALB:** provides a stable HTTP entry point and health checks, but costs while provisioned.
- **RDS PostgreSQL (optional):** private, encrypted, disabled by default, and not connected to the stateless API. Enabling it incurs database, storage, and potentially backup charges. The current configuration deletes it without a final snapshot.
- **CloudWatch:** task logs retained for seven days. Optional CPU/memory alarms can incur charges.
- **IAM/OIDC:** ECS execution permissions are scoped to the project ECR repository and log group. The stateless API has no task role. GitHub receives temporary credentials only for the configured repository branch.

## Billable resources

An AWS deployment is not safe to assume free and does not fit a strict ₹0 budget. Potential charges include the Application Load Balancer, Fargate tasks, public IPv4 addresses, ECR image storage and scanning, CloudWatch logs and optional alarms, data transfer, and optional RDS. NAT Gateways and VPC endpoints are not created here; adding them can create more recurring charges. Review current regional AWS pricing before provisioning. For a short test, test locally first, keep RDS/alarms off, provision only when ready, and destroy the full stack immediately after verification. Do not treat stopping ECS as complete cleanup.
