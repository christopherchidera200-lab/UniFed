terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }

  # Bootstrap locally first, then create the state bucket + lock table and uncomment.
  # backend "s3" {
  #   bucket         = "cloudintel-tfstate"
  #   key            = "dev/terraform.tfstate"
  #   region         = "eu-west-1"
  #   dynamodb_table = "cloudintel-tflock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}
