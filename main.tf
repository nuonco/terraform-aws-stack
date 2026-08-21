module "vpc" {
  source = "./modules/vpc"

  prefix = local.prefix
  tags   = local.tags
}

module "runner" {
  source = "./modules/runner"
  count  = var.runner_enabled ? 1 : 0

  prefix                       = local.prefix
  tags                         = local.tags
  vpc_id                       = module.vpc.vpc_id
  runner_subnet_id             = module.vpc.runner_subnet_id
  runner_security_group        = module.vpc.runner_security_group_id
  runner_instance_profile_name = aws_iam_instance_profile.runner.name
  runner_api_url               = local.runner_api_url
  runner_id                    = local.runner_id
  nuon_install_id              = local.nuon_install_id
  instance_type                = local.runner_machine_type
}
