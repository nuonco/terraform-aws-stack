terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    stack = {
      source  = "nuonco/stack"
      version = ">= 0.4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "stack" {}
