# Minimal example: everything the module needs is one input.
#
# Runner details, IAM permissions, roles, install inputs, and secret metadata
# are all read from the Nuon control plane, keyed by install_id and authorized
# by the stack provider's credentials.

module "aws_stack" {
  source = "../../"

  install_id = var.install_id
}
