terraform {
  required_version = ">= 1.5"

  required_providers {
    # Constrained to >= 6.0: the module is developed and tested against 6.x,
    # and `data.aws_region.region` (checks.tf) does not exist in 5.x, where the
    # attribute was named `name`.
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
    # >= 0.8.0: stack_version_id on both the data source and the phone-home
    # resource, without which a newly generated stack version produces no diff.
    stack = {
      source  = "nuonco/stack"
      version = ">= 0.8.0"
    }
  }
}
