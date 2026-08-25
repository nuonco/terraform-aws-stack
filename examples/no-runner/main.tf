# Networking, IAM, and secrets without a runner.
#
# `runner_enabled = false` skips the runner module entirely — no launch
# template, ASG, or log group. Useful for validating IAM and networking before
# bringing a runner online. `runner_asg_name` and `runner_log_group_name`
# return empty strings in this mode.
#
# Note this is not a working install on its own: the runner is what polls the
# control plane and executes jobs. See examples/minimal for the normal case.

module "aws_stack" {
  source = "../../"

  install_id     = var.install_id
  runner_enabled = false
}
