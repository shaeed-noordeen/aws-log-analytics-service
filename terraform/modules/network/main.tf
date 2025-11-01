locals {
  sanitized_name = replace(lower(var.name), "/[^a-z0-9-]/", "-")

  base_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  vpc_name          = "${local.sanitized_name}-vpc"
  igw_name          = "${local.sanitized_name}-igw"
  public_rt_name    = "${local.sanitized_name}-public-rt"
  s3_endpoint_name  = "${local.sanitized_name}-s3-endpoint"
  app_sg_name       = "${local.sanitized_name}-app-sg"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.base_tags, { Name = local.vpc_name })
}

resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    local.base_tags,
    {
      Name = format("%s-public-subnet-%d", local.sanitized_name, count.index + 1)
    }
  )
}

resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, var.az_count + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    local.base_tags,
    {
      Name = format("%s-private-subnet-%d", local.sanitized_name, count.index + 1)
    }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.base_tags, { Name = local.igw_name })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.base_tags, { Name = local.public_rt_name })
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count  = var.az_count
  domain = "vpc"

  tags = merge(
    local.base_tags,
    {
      Name = format("%s-nat-eip-%d", local.sanitized_name, count.index + 1)
    }
  )
}

resource "aws_nat_gateway" "main" {
  count         = var.az_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    local.base_tags,
    {
      Name = format("%s-nat-gw-%d", local.sanitized_name, count.index + 1)
    }
  )
}

resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(
    local.base_tags,
    {
      Name = format("%s-private-rt-%d", local.sanitized_name, count.index + 1)
    }
  )
}

resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  tags = merge(local.base_tags, { Name = local.s3_endpoint_name })
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count           = var.az_count
  route_table_id  = aws_route_table.private[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_security_group" "app" {
  name        = local.app_sg_name
  description = "Security group for ${var.name} application resources."
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.base_tags, { Name = local.app_sg_name })
}

data "aws_availability_zones" "available" {
  state = "available"
}
