resource "aws_vpc" "network" {
  count      = var.subnet_id == null ? 1 : 0
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

data "aws_subnet" "subnet" {
  count = var.subnet_id == null ? 0 : 1
  id    = var.subnet_id
}

locals {
  subnet_id         = var.subnet_id == null ? aws_subnet.subnet[0].id : var.subnet_id
  vpc_id            = var.subnet_id == null ? aws_vpc.network[0].id : data.aws_subnet.subnet[0].vpc_id
}

# Internet gateway to give our VPC access to the outside world
resource "aws_internet_gateway" "gw" {
  count  = var.subnet_id == null ? 1 : 0
  vpc_id = local.vpc_id
}

# Grant the VPC internet access by creating a very generic
# destination CIDR ("catch all" - the least specific possible)
# such that we route traffic to outside as a last resource for
# any route that the table doesn't know about.
resource "aws_route" "internet_access" {
  count                  = var.subnet_id == null ? 1 : 0
  route_table_id         = aws_vpc.network[0].main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw[0].id
}

resource "aws_subnet" "subnet" {
  count                   = var.subnet_id == null ? 1 : 0
  vpc_id                  = local.vpc_id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = local.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}-subnet"
  }
}

resource "aws_security_group" "allow_out_any" {
  name   = "${var.cluster_name}-allow_out_any"
  vpc_id = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  all_tags   = toset(flatten([for key, value in module.design.instances : value.tags]))
  sec_groups = toset([for name, rule in var.firewall_rules : rule.tag if contains(local.all_tags, rule.tag)])
}

resource "aws_security_group" "external" {
  for_each    = local.sec_groups
  name        = "${var.cluster_name}-secgroup-${each.key}"
  description = "${var.cluster_name} external security group for ${each.key} instances"
  vpc_id      = local.vpc_id

  dynamic "ingress" {
    for_each = { for name, values in var.firewall_rules : name => values if values.tag == each.value }
    iterator = rule
    content {
      description      = rule.key
      from_port        = rule.value.from_port
      to_port          = rule.value.to_port
      protocol         = rule.value.protocol
      cidr_blocks      = rule.value.ethertype == "IPv4" ? [rule.value.cidr] : null
      ipv6_cidr_blocks = rule.value.ethertype == "IPv6" ? [rule.value.cidr] : null
    }
  }

  tags = {
    Name = "${var.cluster_name}-secgroup-${each.key}"
  }
}

resource "aws_security_group" "allow_any_inside_sg" {
  name = "${var.cluster_name}-allow_any_inside_sg"

  vpc_id = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.cluster_name}-allow_any_inside_sg"
  }
}

moved {
  from = aws_security_group.allow_any_inside_vpc
  to   = aws_security_group.allow_any_inside_sg
}

resource "aws_network_interface" "nic" {
  for_each       = module.design.instances
  subnet_id      = local.subnet_id
  interface_type = contains(each.value["tags"], "efa") ? "efa" : null

  security_groups = concat(
    [
      aws_security_group.allow_any_inside_sg.id,
      aws_security_group.allow_out_any.id,
    ],
    [
      for tag, value in aws_security_group.external : value.id if contains(each.value.tags, tag)
    ]
  )

  tags = {
    Name = "${var.cluster_name}-${each.key}-if"
  }
}

resource "aws_eip" "public_ip" {
  for_each = {
    for x, values in module.design.instances : x => true if contains(values.tags, "public")
  }
  domain            = "vpc"
  network_interface = aws_network_interface.nic[each.key].id
  depends_on        = [aws_internet_gateway.gw]
  tags = {
    Name = "${var.cluster_name}-${each.key}-eip"
  }
}
