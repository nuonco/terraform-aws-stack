module "vpc" {
  source = "./modules/vpc"

  prefix = local.prefix
  tags   = local.tags
}

module "runner" {
  source = "./modules/runner"

  prefix                       = local.prefix
  tags                         = local.tags
  vpc_id                       = module.vpc.vpc_id
  runner_subnet_id             = module.vpc.runner_subnet_id
  runner_security_group        = module.vpc.runner_security_group_id
  runner_instance_profile_name = aws_iam_instance_profile.runner.name
  runner_init_script_url       = var.runner_init_script_url
  runner_api_url               = var.runner_api_url
  runner_api_token             = var.runner_api_token
  runner_id                    = var.runner_id
  nuon_install_id              = var.nuon_install_id
}
