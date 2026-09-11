locals {
  telemetry_ingress_enabled = var.runner_enabled && var.enable_telemetry_ingress
  telemetry_endpoint        = local.telemetry_ingress_enabled ? "http://${aws_lb.telemetry[0].dns_name}:4318" : ""
}

resource "aws_security_group" "telemetry_load_balancer" {
  count = local.telemetry_ingress_enabled ? 1 : 0

  name        = "${local.prefix}-telemetry-lb"
  description = "Private OTLP ingress for ${local.prefix}"
  vpc_id      = local.network.vpc_id
  tags        = merge(local.tags, { Name = "${local.prefix}-telemetry-lb" })

  lifecycle {
    precondition {
      condition     = !local.vpc_from_template || local.network.vpc_ipv4_prefix_list_id != ""
      error_message = "Telemetry ingress requires custom VPC templates to output VpcIpv4PrefixListId. Update the template to supply that output, or set enable_telemetry_ingress = false to opt out."
    }
  }
}

resource "aws_security_group" "telemetry_receiver" {
  count = local.telemetry_ingress_enabled ? 1 : 0

  name        = "${local.prefix}-telemetry-receiver"
  description = "OTLP traffic from the private load balancer to the runner"
  vpc_id      = local.network.vpc_id
  tags        = merge(local.tags, { Name = "${local.prefix}-telemetry-receiver" })
}

resource "aws_vpc_security_group_ingress_rule" "telemetry_load_balancer" {
  count = local.telemetry_ingress_enabled ? 1 : 0

  security_group_id = aws_security_group.telemetry_load_balancer[0].id
  prefix_list_id    = local.network.vpc_ipv4_prefix_list_id
  ip_protocol       = "tcp"
  from_port         = 4318
  to_port           = 4318
}

resource "aws_vpc_security_group_egress_rule" "telemetry_load_balancer" {
  count = local.telemetry_ingress_enabled ? 1 : 0

  security_group_id            = aws_security_group.telemetry_load_balancer[0].id
  referenced_security_group_id = aws_security_group.telemetry_receiver[0].id
  ip_protocol                  = "tcp"
  from_port                    = 4318
  to_port                      = 4318
}

resource "aws_vpc_security_group_ingress_rule" "telemetry_receiver" {
  count = local.telemetry_ingress_enabled ? 1 : 0

  security_group_id            = aws_security_group.telemetry_receiver[0].id
  referenced_security_group_id = aws_security_group.telemetry_load_balancer[0].id
  ip_protocol                  = "tcp"
  from_port                    = 4318
  to_port                      = 4318
}

resource "aws_lb" "telemetry" {
  count = local.telemetry_ingress_enabled ? 1 : 0

  name               = "${substr(local.prefix, 0, 20)}-telemetry"
  internal           = true
  load_balancer_type = "network"
  subnets            = [local.network.runner_subnet_id]
  security_groups    = [aws_security_group.telemetry_load_balancer[0].id]
  tags               = local.tags
}

resource "aws_lb_target_group" "telemetry" {
  count = local.telemetry_ingress_enabled ? 1 : 0

  name        = "${substr(local.prefix, 0, 20)}-telemetry"
  port        = 4318
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = local.network.vpc_id

  health_check {
    enabled  = true
    protocol = "TCP"
    port     = "4318"
  }

  tags = local.tags
}

resource "aws_lb_listener" "telemetry" {
  count = local.telemetry_ingress_enabled ? 1 : 0

  load_balancer_arn = aws_lb.telemetry[0].arn
  port              = 4318
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.telemetry[0].arn
  }
}
