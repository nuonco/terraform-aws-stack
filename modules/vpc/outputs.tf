output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "runner_subnet_id" {
  value = aws_subnet.runner.id

  # Don't expose the runner subnet to consumers (i.e. the runner module)
  # until egress is fully wired up: route table association implies the
  # route table exists, which in turn implies the IGW or NAT GW is ready.
  # Without this gate the runner ASG can launch an instance that boots
  # before its default route is in place, and user_data fails to reach
  # the internet on first run.
  depends_on = [aws_route_table_association.runner]
}

output "runner_security_group_id" {
  value = aws_security_group.runner.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.main.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.main.id
}
