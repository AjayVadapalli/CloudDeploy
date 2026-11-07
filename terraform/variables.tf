variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "ecs-spring-api"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Provide exactly two AZs for the Application Load Balancer subnets."
  }
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "task_cpu" {
  type    = number
  default = 256
}

variable "task_memory" {
  type    = number
  default = 512
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "image_uri" {
  type        = string
  description = "Existing ECR image URI, for example repository-url:git-sha. Push an image before creating the ECS service."

  validation {
    condition     = length(trimspace(var.image_uri)) > 0
    error_message = "image_uri must be set to an existing container image URI."
  }
}

variable "enable_rds" {
  type        = bool
  default     = false
  description = "Creates a private PostgreSQL instance. RDS keeps billing while running and may incur storage/backup charges when stopped."
}

variable "enable_alarms" {
  type        = bool
  default     = false
  description = "Creates two CloudWatch alarms. Disabled by default to limit billable resources."
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "github_owner" {
  type        = string
  description = "GitHub user or organization that owns this repository."

  validation {
    condition     = length(trimspace(var.github_owner)) > 0
    error_message = "github_owner is required to scope the GitHub OIDC trust policy."
  }
}

variable "github_repository" {
  type        = string
  description = "Repository name, without owner."

  validation {
    condition     = length(trimspace(var.github_repository)) > 0
    error_message = "github_repository is required to scope the GitHub OIDC trust policy."
  }
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "tags" {
  type    = map(string)
  default = { Project = "ecs-spring-api", ManagedBy = "Terraform" }
}
