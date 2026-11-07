output "ecr_repository_url" { value = aws_ecr_repository.api.repository_url }
output "ecs_cluster_name" { value = aws_ecs_cluster.main.name }
output "ecs_service_name" { value = aws_ecs_service.api.name }
output "ecs_task_definition_family" { value = aws_ecs_task_definition.api.family }
output "load_balancer_url" { value = "http://${aws_lb.api.dns_name}" }
output "github_actions_role_arn" { value = aws_iam_role.github_actions.arn }
output "rds_endpoint" { value = var.enable_rds ? aws_db_instance.app[0].address : null }
