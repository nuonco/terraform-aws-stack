# A vendor who customised their CloudFormation VPC has components that read those
# extra resources back by tag, so building this module's VPC instead would leave
# them unresolvable on the Terraform path.
resource "aws_cloudformation_stack" "vpc" {
  count = local.vpc_nested_template_url != "" ? 1 : 0

  name         = "${local.prefix}-vpc"
  template_url = local.vpc_nested_template_url

  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"]

  parameters = {
    NuonInstallID        = local.nuon_install_id
    NuonOrgID            = local.nuon_org_id
    NuonAppID            = local.nuon_app_id
    EnableFirewall       = var.enable_dns_firewall ? "true" : "false"
    EgressAllowedDomains = join(",", var.egress_allowed_domains)
  }

  tags = local.tags
}

locals {
  vpc_from_template = length(aws_cloudformation_stack.vpc) > 0

  vpc_template_outputs = local.vpc_from_template ? aws_cloudformation_stack.vpc[0].outputs : {}

  # The reference template renamed this output; accept either spelling so the
  # module works against both.
  vpc_template_cidr = coalesce(
    lookup(local.vpc_template_outputs, "VpcCidrBlock", ""),
    lookup(local.vpc_template_outputs, "CIDRBlock", ""),
  )

  # Single indirection for the rest of the module, so nothing else needs to know
  # which of the two built the network.
  network = local.vpc_from_template ? {
    vpc_id                     = lookup(local.vpc_template_outputs, "VPC", "")
    vpc_cidr                   = local.vpc_template_cidr
    public_subnet_ids          = split(",", lookup(local.vpc_template_outputs, "PublicSubnets", ""))
    private_subnet_ids         = split(",", lookup(local.vpc_template_outputs, "PrivateSubnets", ""))
    runner_subnet_id           = lookup(local.vpc_template_outputs, "RunnerSubnet", "")
    runner_security_group_id   = lookup(local.vpc_template_outputs, "SecurityGroupId", "")
    dns_firewall_rule_group_id = lookup(local.vpc_template_outputs, "DnsFirewallRuleGroupId", "")
    } : {
    vpc_id                     = one(module.vpc[*].vpc_id)
    vpc_cidr                   = one(module.vpc[*].vpc_cidr)
    public_subnet_ids          = try(one(module.vpc[*].public_subnet_ids), [])
    private_subnet_ids         = try(one(module.vpc[*].private_subnet_ids), [])
    runner_subnet_id           = one(module.vpc[*].runner_subnet_id)
    runner_security_group_id   = one(module.vpc[*].runner_security_group_id)
    dns_firewall_rule_group_id = one(module.vpc[*].dns_firewall_rule_group_id)
  }
}
