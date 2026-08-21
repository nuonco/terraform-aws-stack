terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    stack = {
      source  = "nuonco/stack"
      version = ">= 0.3.0"
    }
  }
}

# The module declares no providers of its own, so configuring both is the
# caller's job.
#
# The aws region must match the region the Nuon control plane has recorded for
# this install — the module's `check` block verifies this at plan time.
provider "aws" {
  region = var.aws_region
}

provider "stack" {
  api_url = var.api_url
}
