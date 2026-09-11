module "vpc" {
  source = "./modules/vpc"
  count  = local.vpc_nested_template_url != "" ? 0 : 1

  prefix                 = local.prefix
  tags                   = local.tags
  enable_dns_firewall    = var.enable_dns_firewall
  egress_allowed_domains = var.egress_allowed_domains
}

module "runner" {
  source = "./modules/runner"
  count  = var.runner_enabled ? 1 : 0

  # The instance needs egress the moment user_data runs, but the NAT gateway
  # and the runner subnet's route association don't feed any output the runner
  # module consumes, so nothing orders them ahead of the ASG implicitly.
  # Register the ASG only after the target group is attached to its listener.
  depends_on = [module.vpc, aws_cloudformation_stack.vpc, aws_lb_listener.telemetry]

  prefix                        = local.prefix
  tags                          = local.tags
  vpc_id                        = local.network.vpc_id
  runner_subnet_id              = local.network.runner_subnet_id
  runner_security_group         = local.network.runner_security_group_id
  additional_security_group_ids = local.telemetry_ingress_enabled ? [aws_security_group.telemetry_receiver[0].id] : []
  target_group_arns             = local.telemetry_ingress_enabled ? [aws_lb_target_group.telemetry[0].arn] : []
  runner_instance_profile_name  = aws_iam_instance_profile.runner.name
  runner_api_url                = local.runner_api_url
  runner_id                     = local.runner_id
  nuon_install_id               = local.nuon_install_id
  instance_type                 = local.runner_machine_type
}
