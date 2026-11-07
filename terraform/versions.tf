terraform {
  required_version = ">= 1.10.0, < 2.0.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.66" }
    tls = { source = "hashicorp/tls", version = "~> 4.1" }
  }
  # For team use, configure an S3 backend and state locking before applying.
  # Backend settings are intentionally not hardcoded in this beginner sample.
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = var.tags }
}

provider "tls" {}

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}
