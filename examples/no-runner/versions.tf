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

# The module declares no providers of its own, so configuring both is the
# caller's job.
#
# The aws region must match the region the Nuon control plane has recorded for
# this install — the module's `check` block verifies this at plan time.
provider "aws" {
  region = var.aws_region
}

# Credentials: api_token, else NUON_API_TOKEN, else an ambient OIDC token
# exchanged for a short-lived one (which is what org_id is for). In CI, prefer
# OIDC and set neither api_token nor NUON_API_TOKEN.
provider "stack" {
  api_url   = var.api_url
  api_token = var.api_token
  org_id    = var.org_id
}
