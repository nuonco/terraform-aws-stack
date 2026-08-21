# Minimal example: networking, IAM, and secrets only.
#
# `runner_enabled = false` skips the runner module entirely (no launch
# template, ASG, or log group). Useful for validating IAM and networking before
# bringing a runner online. `runner_asg_name` and `runner_log_group_name`
# return empty strings in this mode.

module "install_stack" {
  source = "../../"

  phone_home_id  = var.phone_home_id
  runner_enabled = false
}
