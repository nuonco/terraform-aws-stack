provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      "install.nuon.co/id" = var.nuon_install_id
      "nuon_install_id"    = var.nuon_install_id
    }
  }
}
