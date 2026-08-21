terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

# The module deliberately declares no provider of its own, so configuring it is
# the caller's job. `default_tags` here is optional — the module already tags
# every taggable resource it creates with the install ID.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      "install.nuon.co/id" = var.nuon_install_id
      "nuon_install_id"    = var.nuon_install_id
    }
  }
}
