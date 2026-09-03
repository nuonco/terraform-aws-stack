# Optional Route 53 Resolver DNS Firewall. Off by default, matching
# EnableFirewall=false on the CloudFormation VPC template. When enabled,
# outbound DNS is blocked unless the domain is in egress_allowed_domains.

resource "aws_route53_resolver_firewall_domain_list" "allow" {
  count   = var.enable_dns_firewall && length(var.egress_allowed_domains) > 0 ? 1 : 0
  name    = "${var.prefix}-egress-allow-list"
  domains = var.egress_allowed_domains
  tags    = var.tags
}

resource "aws_route53_resolver_firewall_domain_list" "block_all" {
  count   = var.enable_dns_firewall ? 1 : 0
  name    = "${var.prefix}-egress-block-all"
  domains = ["*"]
  tags    = var.tags
}

resource "aws_route53_resolver_firewall_rule_group" "egress" {
  count = var.enable_dns_firewall ? 1 : 0
  name  = "${var.prefix}-egress-dns-firewall"
  tags  = var.tags
}

resource "aws_route53_resolver_firewall_rule" "allow" {
  count = var.enable_dns_firewall && length(var.egress_allowed_domains) > 0 ? 1 : 0

  name                               = "${var.prefix}-egress-allow"
  action                             = "ALLOW"
  firewall_domain_list_id            = aws_route53_resolver_firewall_domain_list.allow[0].id
  firewall_domain_redirection_action = "TRUST_REDIRECTION_DOMAIN"
  firewall_rule_group_id             = aws_route53_resolver_firewall_rule_group.egress[0].id
  priority                           = 100
}

resource "aws_route53_resolver_firewall_rule" "block" {
  count = var.enable_dns_firewall ? 1 : 0

  name                    = "${var.prefix}-egress-block"
  action                  = "BLOCK"
  block_response          = "NODATA"
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.block_all[0].id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.egress[0].id
  priority                = 200
}

resource "aws_route53_resolver_firewall_rule_group_association" "vpc" {
  count = var.enable_dns_firewall ? 1 : 0

  name                   = "${var.prefix}-egress-dns-firewall"
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.egress[0].id
  priority               = 101
  vpc_id                 = aws_vpc.main.id
  tags                   = var.tags
}
