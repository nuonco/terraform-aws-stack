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
    # >= 0.4.0: this module reads config by install_id and reports via the
    # stack_phone_home resource's phone_home_url, neither of which exist in
    # 0.3.x, where phone_home_id was both the key and the credential.
    stack = {
      source  = "nuonco/stack"
      version = ">= 0.4.0"
    }
  }
}
