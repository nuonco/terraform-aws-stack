data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Span public + private subnets across 2 AZs so EKS (and other multi-AZ
  # services the customer's components may provision) has the required AZ
  # diversity. Runner stays single-AZ — it's a single ASG instance.
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

resource "aws_vpc" "main" {
  cidr_block           = "10.128.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${var.prefix}-vpc" })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.prefix}-igw" })
}

# Migrate from the previous single-AZ layout (single `aws_subnet.public` /
# `aws_subnet.private` resources) to the for_each layout. Without these,
# Terraform plans a destroy+create that races on the existing CIDRs.
moved {
  from = aws_subnet.public
  to   = aws_subnet.public[0]
}

moved {
  from = aws_subnet.private
  to   = aws_subnet.private[0]
}

moved {
  from = aws_route_table_association.public
  to   = aws_route_table_association.public[0]
}

moved {
  from = aws_route_table_association.private
  to   = aws_route_table_association.private[0]
}

resource "aws_subnet" "public" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.128.${count.index * 16}.0/24"
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name                     = "${var.prefix}-public-subnet-${count.index}"
    visibility               = "public"
    "network.nuon.co/domain" = "public"
  })
}

resource "aws_subnet" "private" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.128.${count.index * 16 + 1}.0/24"
  availability_zone = local.azs[count.index]
  tags = merge(var.tags, {
    Name                     = "${var.prefix}-private-subnet-${count.index}"
    visibility               = "private"
    "network.nuon.co/domain" = "internal"
  })
}

resource "aws_subnet" "runner" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.128.2.0/24"
  availability_zone = local.azs[0]
  tags = merge(var.tags, {
    Name                     = "${var.prefix}-runner-subnet"
    visibility               = "private"
    "network.nuon.co/domain" = "runner"
  })
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.prefix}-nat-eip" })
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, { Name = "${var.prefix}-nat" })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.prefix}-public-rt" })

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.prefix}-private-rt" })

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "runner" {
  subnet_id      = aws_subnet.runner.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "runner" {
  name        = "${var.prefix}-runner-sg"
  description = "Nuon runner security group for ${var.prefix}"
  vpc_id      = aws_vpc.main.id
  tags = merge(var.tags, {
    Name                     = "${var.prefix}-runner-sg"
    "network.nuon.co/domain" = "runner"
  })

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
}
