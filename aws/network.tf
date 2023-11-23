resource "aws_vpc" "network" {
  cidr_block = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

# Internet gateway to give our VPC access to the outside world
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.network.id
}

resource "aws_egress_only_internet_gateway" "ipv6_egress_igw" {
  vpc_id = aws_vpc.network.id
}


# Grant the VPC internet access by creating a very generic
# destination CIDR ("catch all" - the least specific possible)
# such that we route traffic to outside as a last resource for
# any route that the table doesn't know about.
resource "aws_route" "internet_access" {
  route_table_id           = aws_vpc.network.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route" "internet_access_ipv6" {
  route_table_id              = aws_vpc.network.main_route_table_id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.ipv6_egress_igw.id
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.network.id
  cidr_block = cidrsubnet(aws_vpc.network.cidr_block, 8, 0)
  availability_zone = local.availability_zone
  assign_ipv6_address_on_creation = true
  ipv6_cidr_block = aws_vpc.network.ipv6_cidr_block

  tags = {
    Name = "${var.cluster_name}-private-subnet"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.network.id
  cidr_block = cidrsubnet(aws_vpc.network.cidr_block, 8, 1)
  availability_zone = local.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}-public-subnet"
  }
}

resource "aws_security_group" "allow_out_any" {
  name   = "allow_out_any"
  vpc_id = aws_vpc.network.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
}

locals {
  all_tags   = toset(flatten([ for key, value in module.design.instances: value.tags ]))
  sec_groups = toset([ for name, rule in var.firewall_rules: rule.tag if contains(local.all_tags, rule.tag) ])
}

resource "aws_security_group" "external" {
  for_each    = local.sec_groups
  name        = "${var.cluster_name}-secgroup-${each.key}"
  description = "${var.cluster_name} external security group for ${each.key} instances"
  vpc_id      = aws_vpc.network.id

  dynamic "ingress" {
    for_each = { for name, values in var.firewall_rules: name => values if values.tag == each.value }
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

resource "aws_security_group" "allow_any_inside_vpc" {
  name = "allow_any_inside_vpc"

  vpc_id = aws_vpc.network.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.network.cidr_block]
    self        = true
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.network.cidr_block]
    self        = true
  }

  tags = {
    Name = "${var.cluster_name}-allow_any_inside_vpc"
  }
}

locals {
  # Tags that require an IPV4 address
  # - public: to match record A
  # - puppet: because git clone does not work with ipv6
  ipv4_tags = ["public", "puppet"]
}

resource "aws_network_interface" "nic" {
  for_each        = module.design.instances
  subnet_id       = length(setintersection(each.value.tags, local.ipv4_tags)) > 0 ? aws_subnet.public_subnet.id : aws_subnet.private_subnet.id 
  interface_type  = contains(each.value["tags"], "efa") ? "efa" : null

  security_groups = concat(
    [
      aws_security_group.allow_any_inside_vpc.id,
      aws_security_group.allow_out_any.id,
    ],
    [
      for tag, value in aws_security_group.external: value.id if contains(each.value.tags, tag)
    ]
  )

  tags = {
    Name = "${var.cluster_name}-${each.key}-if"
  }
}
