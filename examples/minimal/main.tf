# Minimal example: networking, IAM, and secrets only.
#
# `runner_enabled = false` skips the runner module entirely (no launch
# template, ASG, or log group). Useful for validating IAM and networking before
# bringing a runner online. `runner_asg_name` and `runner_log_group_name`
# return empty strings in this mode.

module "install_stack" {
  source = "../../"

  aws_region                 = var.aws_region
  nuon_install_id            = var.nuon_install_id
  nuon_org_id                = var.nuon_org_id
  nuon_app_id                = var.nuon_app_id
  runner_api_url             = var.runner_api_url
  runner_id                  = var.runner_id
  phone_home_url             = var.phone_home_url
  nuon_support_iam_role_arns = var.nuon_support_iam_role_arns

  runner_enabled = false

  maintenance_permissions = ["ec2:Describe*"]
}
