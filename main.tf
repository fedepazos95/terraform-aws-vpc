locals {
  public_subnets_len     = max(length(var.azs), length(var.public_subnets))
  private_subnets_len    = max(length(var.azs), length(var.private_subnets))
  create_public_subnets  = local.public_subnets_len > 0
  create_private_subnets = local.private_subnets_len > 0
  azs                    = length(var.azs) > 0 ? var.azs : slice(data.aws_availability_zones.available.names, 0, max(local.public_subnets_len, local.private_subnets_len))
}

################################################################################
# VPC
################################################################################

resource "aws_vpc" "this" {
  cidr_block = var.cidr

  tags = merge(
    { "Name" = var.name },
    var.tags,
    var.vpc_tags,
  )
}

################################################################################
# Subnets
################################################################################

resource "aws_subnet" "private" {
  count = local.create_private_subnets ? local.private_subnets_len : 0

  vpc_id            = aws_vpc.this.id
  availability_zone = element(local.azs, count.index)
  cidr_block        = try(element(var.private_subnets, count.index), cidrsubnet(var.cidr, 8, count.index))

  tags = merge(
    {
      Name = try(
        var.private_subnet_names[count.index],
        format("${var.name}-${var.private_subnet_suffix}-%s", element(local.azs, count.index))
      )
    },
    var.tags,
    var.private_subnet_tags,
  )
}

resource "aws_subnet" "public" {
  count = local.create_public_subnets ? local.public_subnets_len : 0

  vpc_id            = aws_vpc.this.id
  availability_zone = element(local.azs, count.index)
  cidr_block        = try(element(var.public_subnets, count.index), cidrsubnet(var.cidr, 8, count.index + local.private_subnets_len))

  tags = merge(
    {
      Name = try(
        var.public_subnet_names[count.index],
        format("${var.name}-${var.public_subnet_suffix}-%s", element(local.azs, count.index))
      )
    },
    var.tags,
    var.public_subnet_tags,
  )
}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "this" {
  count = local.create_public_subnets ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = var.name
    },
    var.tags,
    var.igw_tags
  )
}

################################################################################
# NAT Gateway
################################################################################

resource "aws_eip" "nat" {
  count = local.create_public_subnets ? local.public_subnets_len : 0

  domain = "vpc"

  tags = merge(
    {
      "Name" = format(
        "${var.name}-%s",
        element(local.azs, count.index),
      )
    },
    var.tags,
    var.nat_eip_tags,
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = local.create_public_subnets ? local.public_subnets_len : 0

  allocation_id = element(aws_eip.nat[*].id, count.index)
  subnet_id     = element(aws_subnet.public[*].id, count.index)

  tags = merge(
    {
      "Name" = format(
        "${var.name}-%s",
        element(local.azs, count.index),
      )
    },
    var.tags,
    var.nat_gateway_tags,
  )

  depends_on = [aws_internet_gateway.this]
}

################################################################################
# Route Tables
################################################################################

resource "aws_route_table" "private" {
  count = local.create_private_subnets ? local.private_subnets_len : 0

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = var.nat_gateway_destination_cidr_block
    nat_gateway_id = element(aws_nat_gateway.this[*].id, count.index)
  }

  tags = merge(
    {
      Name = "${var.name}-${var.private_subnet_suffix}"
    },
    var.tags,
    var.private_route_table_tags
  )
}

resource "aws_route_table_association" "private" {
  count = local.create_private_subnets ? local.private_subnets_len : 0

  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(aws_route_table.private[*].id, count.index)
}

resource "aws_route_table" "public" {
  count = local.create_public_subnets ? 1 : 0

  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = one(aws_internet_gateway.this).id
  }

  tags = merge(
    {
      Name = "${var.name}-${var.public_subnet_suffix}"
    },
    var.tags,
    var.public_route_table_tags
  )
}

resource "aws_route_table_association" "public" {
  count = local.create_public_subnets ? local.public_subnets_len : 0

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = one(aws_route_table.public).id
}

################################################################################
# Network ACLs
################################################################################

resource "aws_network_acl" "private" {
  count = local.create_private_subnets ? 1 : 0

  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.private[*].id

  dynamic "ingress" {
    for_each = var.private_inbound_acl_rules
    content {
      protocol   = ingress.value["protocol"]
      rule_no    = ingress.value["number"]
      action     = ingress.value["action"]
      cidr_block = lookup(ingress.value, "cidr_block", null)
      from_port  = lookup(ingress.value, "from_port", null)
      to_port    = lookup(ingress.value, "to_port", null)
    }
  }

  dynamic "egress" {
    for_each = var.private_outbound_acl_rules
    content {
      protocol   = egress.value["protocol"]
      rule_no    = egress.value["number"]
      action     = egress.value["action"]
      cidr_block = lookup(egress.value, "cidr_block", null)
      from_port  = lookup(egress.value, "from_port", null)
      to_port    = lookup(egress.value, "to_port", null)
    }
  }

  tags = merge(
    { "Name" = "${var.name}-${var.private_subnet_suffix}" },
    var.tags,
    var.private_acl_tags,
  )
}

resource "aws_network_acl" "public" {
  count = local.create_public_subnets ? 1 : 0

  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.public[*].id

  dynamic "ingress" {
    for_each = var.public_inbound_acl_rules
    content {
      protocol   = ingress.value["protocol"]
      rule_no    = ingress.value["number"]
      action     = ingress.value["action"]
      cidr_block = lookup(ingress.value, "cidr_block", null)
      from_port  = lookup(ingress.value, "from_port", null)
      to_port    = lookup(ingress.value, "to_port", null)
    }
  }

  dynamic "egress" {
    for_each = var.public_outbound_acl_rules
    content {
      protocol   = egress.value["protocol"]
      rule_no    = egress.value["number"]
      action     = egress.value["action"]
      cidr_block = lookup(egress.value, "cidr_block", null)
      from_port  = lookup(egress.value, "from_port", null)
      to_port    = lookup(egress.value, "to_port", null)
    }
  }

  tags = merge(
    { "Name" = "${var.name}-${var.public_subnet_suffix}" },
    var.tags,
    var.public_acl_tags,
  )
}

################################################################################
# Default Resources
# Manage the default resources so Terraform removes all defined values from them
################################################################################

resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  tags = merge(
    { "Name" = "${var.name}-default" },
    var.tags,
  )
}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.this.default_network_acl_id

  tags = merge(
    { "Name" = "${var.name}-default" },
    var.tags,
  )
}
