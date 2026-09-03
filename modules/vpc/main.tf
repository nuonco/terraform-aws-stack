data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Match aws-cloudformation-templates/vpc/eks/default: 3 AZs, CFN default CIDRs.
  # Runner stays single-AZ — it's a single ASG instance.
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  vpc_cidr             = "10.128.0.0/16"
  public_subnet_cidrs  = ["10.128.0.0/26", "10.128.0.64/26", "10.128.0.128/26"]
  private_subnet_cidrs = ["10.128.130.0/24", "10.128.132.0/24", "10.128.134.0/24"]
  runner_subnet_cidr   = "10.128.128.0/24"
}

resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${var.prefix}-vpc" })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.prefix}-igw" })
}

resource "aws_subnet" "public" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name                     = "${var.prefix}-public-subnet-az${count.index + 1}"
    visibility               = "public"
    "network.nuon.co/domain" = "public"
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_subnet" "private" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]
  tags = merge(var.tags, {
    Name                              = "${var.prefix}-private-subnet-az${count.index + 1}"
    visibility                        = "private"
    "network.nuon.co/domain"          = "internal"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_subnet" "runner" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.runner_subnet_cidr
  availability_zone = local.azs[0]
  tags = merge(var.tags, {
    Name                     = "${var.prefix}-private-runner-subnet-az1"
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
