terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Local backend for CI validation (no remote state bucket required to run
  # fmt/validate). For real deployments, override via -backend-config=ci.tfbackend
  # or switch to an S3 backend with DynamoDB locking.
  backend "local" {
    path = "tfstate/ci.tfstate"
  }
}

# AWS primary provider (ADUN reference node: af-south-1 — Cape Town, closest to Nigeria)
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project   = "unifed"
      Node      = var.node_slug # e.g. "adun"
      ManagedBy = "terraform"
      Stage     = var.stage
    }
  }
}
