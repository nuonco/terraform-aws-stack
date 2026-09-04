resource "aws_cloudformation_stack" "custom" {
  count = local.custom_stacks_template_url != "" ? 1 : 0

  name         = "${local.prefix}-custom-stacks"
  template_url = local.custom_stacks_template_url

  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"]

  parameters = merge(
    {
      VPC            = module.vpc.vpc_id
      CIDRBlock      = module.vpc.vpc_cidr
      RunnerSubnet   = module.vpc.runner_subnet_id
      PublicSubnets  = join(",", module.vpc.public_subnet_ids)
      PrivateSubnets = join(",", module.vpc.private_subnet_ids)
    },
    local.custom_stack_input_parameters,
  )

  depends_on = [
    module.vpc,
    module.runner,
  ]

  tags = local.tags

  lifecycle {
    precondition {
      condition     = length(local.missing_custom_stack_input_names) == 0
      error_message = "custom_stacks input_parameters reference inputs the install does not have: ${join(", ", local.missing_custom_stack_input_names)}. Known inputs: ${join(", ", keys(local.install_inputs))}."
    }
  }
}
