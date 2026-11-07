# Cost management

AWS pricing depends on region, usage, traffic, retention, and current rates. Check the AWS pricing pages and Cost Explorer for your account before provisioning. This design is **not free**.

| Resource | Cost risk | Continues after desired ECS count is set to zero? |
|---|---|---|
| Application Load Balancer | Hourly and capacity/data processing charges | Yes |
| Fargate tasks | vCPU/memory while tasks run; one task by default | No task compute at zero, but service remains |
| Public IPv4 addresses | Hourly public IPv4 charges may apply | While addresses are allocated/in use |
| RDS PostgreSQL | Instance, storage, backups; substantial fixed cost | Yes; stopping is temporary and storage remains |
| Secrets Manager | Optional RDS-managed master secret may incur secret storage charges | Yes while the secret exists |
| ECR | Image storage and vulnerability scanning | Yes |
| CloudWatch Logs | ingestion, storage, queries | Stored logs remain until retention/deletion |
| CloudWatch alarms | Alarm charges when enabled | Yes |
| NAT Gateway / interface endpoints | Not created in this configuration; can add recurring hourly and transfer charges for private task egress | Yes |
| Internet/data transfer | Depends on traffic and paths | As usage occurs |

Cost-limiting defaults: one Fargate task, 7-day log retention, no RDS, no alarms, no NAT gateway, and no paid VPC endpoints. The task public-IP design trades network isolation for less always-on infrastructure. For one short test, build and test locally first, keep RDS and alarms disabled, provision only when ready to test, and destroy immediately afterward. A public ALB still incurs time-based charges while it exists, even if ECS is stopped.

This repository cannot guarantee a ₹0 AWS bill. The ALB, Fargate, public IPv4 addresses, ECR storage/scans, CloudWatch logs/alarms, data transfer, and optional RDS may be billable even at low usage. GitHub-hosted workflow minutes can also consume the GitHub plan allowance. If you cannot accept any AWS charge, do not provision the stack. If you intentionally run the one-session test, treat the resulting charges as expected and tear down all resources immediately.

## Clean up

1. Stop pushing to `main` so the deployment workflow does not recreate or update resources.
2. Delete all tagged and untagged images from the ECR repository; `force_delete=false` prevents Terraform from deleting a non-empty repository.
3. From `terraform/`, inspect `terraform plan -destroy`, then run `terraform destroy` for this stack. Confirm the plan removes the ALB, ECS service/cluster, VPC/subnets/routes/security groups, ECR repository, CloudWatch log group, IAM roles/policies, and Terraform-managed OIDC provider.
4. If RDS was enabled, account for its no-final-snapshot deletion setting and separately check for snapshots and Secrets Manager secrets. Do not remove an OIDC provider shared by another repository.
5. Verify the resources are gone in AWS, including any leftover public IPs, ECR images/repositories, log groups, RDS objects, and project IAM objects. Check billing reports later because they may lag deletion.

Stopping ECS tasks or setting desired count to zero stops task compute but does not delete the ALB, ECR images, CloudWatch logs, IAM objects, or VPC resources. Those can remain billable until explicitly destroyed or deleted.
