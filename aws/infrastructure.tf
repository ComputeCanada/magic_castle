# Configure the AWS Provider
provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "random_shuffle" "random_az" {
  input = data.aws_availability_zones.available.names
  result_count = 1
}

locals {
  availability_zone = (
    ( var.availability_zone != "" &&
      contains(data.aws_availability_zones.available.names,
               var.availability_zone)
      ?
      var.availability_zone : random_shuffle.random_az.result[0]
    )
  )
}

# Network
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

# Internet gateway to give our VPC access to the outside world
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
}

# Grant the VPC internet access by creating a very generic
# destination CIDR ("catch all" - the least specific possible)
# such that we route traffic to outside as a last resource for
# any route that the table doesn't know about.
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = local.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}-subnet"
  }
}

resource "aws_security_group" "allow_out_any" {
  name   = "allow_out_any"
  vpc_id = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_in_services" {
  name = "allow_in_services"

  description = "Allows services traffic into login nodes"
  vpc_id      = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = var.firewall_rules
    iterator = rule
    content {
      from_port   = rule.value.from_port
      to_port     = rule.value.to_port
      protocol    = rule.value.ip_protocol
      cidr_blocks = [rule.value.cidr]
    }
  }

  tags = {
    Name = "${var.cluster_name}-allow_in_services"
  }
}

resource "aws_security_group" "allow_any_inside_vpc" {
  name = "allow_any_inside_vpc"

  vpc_id = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name = "${var.cluster_name}-allow_any_inside_vpc"
  }
}

resource "aws_key_pair" "key" {
  key_name   = "${var.cluster_name}-key"
  public_key = var.public_keys[0]
}

resource "aws_network_interface" "netifs" {
  for_each        = local.instances
  subnet_id       = aws_subnet.private_subnet.id
  security_groups = concat(
    [
      aws_security_group.allow_any_inside_vpc.id,
      aws_security_group.allow_out_any.id,
    ], 
    contains(each.value["tags"], "public") ? [aws_security_group.allow_in_services.id] : [] 
  )

  tags = {
    Name = "${var.cluster_name}-${each.key}-if"
  }
}

# Instances
resource "aws_instance" "instances" {
  for_each          = local.instances
  instance_type     = each.value.type
  ami               = var.image
  user_data         = base64gzip(local.user_data[each.key])
  availability_zone = local.availability_zone

  key_name          = aws_key_pair.key.key_name

  network_interface {
    network_interface_id = aws_network_interface.netifs[each.key].id
    device_index         = 0
  }

  ebs_optimized = true
  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_disk_size
  }

  tags = {
    Name = format("%s-%s", var.cluster_name, each.key)
  }

  lifecycle {
    ignore_changes = [
      ami
    ]
  }

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_eip" "eip" {
  for_each = {
    for x, values in local.instances : x => true if contains(values.tags, "public")
  }
  vpc        = true
  instance   = aws_instance.instances[each.key].id
  depends_on = [aws_internet_gateway.gw]
  tags = {
    Name = "${var.cluster_name}-${each.key}-eip"
  }
}

locals {
  public_ip = { 
    for x, values in local.instances : x => aws_eip.eip[x].public_ip
    if contains(values.tags, "public")
  }
}

resource "aws_ebs_volume" "volumes" {
  for_each          = local.volumes
  availability_zone = local.availability_zone
  size              = each.value.size
  type              = each.value.type

  tags = {
    Name = "${var.cluster_name}-${each.key}"
  }
}

locals {
  device_names = [
    "/dev/sbf", "/dev/sdg", "/dev/sdh", "/dev/sdi", "/dev/sdj",
    "/dev/sdk", "/dev/sdl", "/dev/sdm", "/dev/sdn", "/dev/sdp"
  ]
}

resource "aws_volume_attachment" "attachments" {
  for_each    = { for k, v in local.volumes : k => v if v.instance != null }
  device_name  = local.device_names[index(local.volume_per_instance[each.value.instance], each.key)]
  volume_id    = aws_ebs_volume.volumes[each.key].id
  instance_id  = aws_instance.instances[each.value.instance].id
  skip_destroy = true
}

locals {
  volume_devices = {
    for ki, vi in var.storage :
    ki => {
      for kj, vj in vi :
      kj => ["/dev/disk/by-id/*${replace(aws_ebs_volume.volumes["${ki}-${kj}"].id, "-", "")}"]
    }
  }
}

locals {
  puppetmaster_id = try(element([for x, values in local.instances : aws_instance.instances[x].id if contains(values.tags, "puppet")], 0), "")
  all_instances = { for x, values in local.instances :
    x => {
      public_ip   = contains(values["tags"], "public") ? local.public_ip[x] : ""
      local_ip    = aws_network_interface.netifs[x].private_ip
      tags        = values["tags"]
      id          = aws_instance.instances[x].id
      hostkeys    = {
        rsa = tls_private_key.rsa_hostkeys[local.host2prefix[x]].public_key_openssh
      }
    }
  }
}