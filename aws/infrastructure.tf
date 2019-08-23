# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Network
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc"
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

  tags = {
    Name = "vpc-subnet"
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
      from_port = rule.value.from_port
      to_port   = rule.value.to_port
      protocol  = rule.value.protocol
      cidr      = rule.value.cidr
    }
  }

  tags = {
    Name = "allow_in_services"
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
    Name = "allow_any_inside_vpc"
  }
}

resource "aws_key_pair" "key" {
  key_name   = "slurm-cloud-key"
  public_key = var.public_keys[0]
}

# Instances
resource "aws_instance" "mgmt" {
  count         = var.instances["mgmt"]["count"]
  instance_type = var.instances["mgmt"]["type"]
  ami           = var.image
  user_data     = data.template_cloudinit_config.mgmt_config[count.index].rendered

  subnet_id                   = aws_subnet.private_subnet.id
  key_name                    = aws_key_pair.key.key_name
  associate_public_ip_address = "true"

  vpc_security_group_ids = [
    aws_security_group.allow_any_inside_vpc.id,
    aws_security_group.allow_out_any.id,
  ]

  tags = {
    Name = format("mgmt%02d", count.index + 1)
  }
}

resource "aws_ebs_volume" "home" {
  count             = lower(var.storage["type"]) == "nfs" ? 1 : 0
  availability_zone = var.availability_zone
  size              = var.storage["home_size"]
  type              = "gp2"

  tags = {
    Name = "home"
  }
}

resource "aws_ebs_volume" "project" {
  count             = lower(var.storage["type"]) == "nfs" ? 1 : 0
  availability_zone = var.availability_zone
  size              = var.storage["project_size"]
  type              = "gp2"

  tags = {
    Name = "project"
  }
}

resource "aws_ebs_volume" "scratch" {
  count             = lower(var.storage["type"]) == "nfs" ? 1 : 0
  availability_zone = var.availability_zone
  size              = var.storage["scratch_size"]
  type              = "gp2"

  tags = {
    Name = "scratch"
  }
}

resource "aws_volume_attachment" "home" {
  count       = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? 1 : 0
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.home[0].id
  instance_id = aws_instance.mgmt[0].id
}

resource "aws_volume_attachment" "project" {
  count       = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? 1 : 0
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.project[0].id
  instance_id = aws_instance.mgmt[0].id
}

resource "aws_volume_attachment" "scratch" {
  count       = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? 1 : 0
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.scratch[0].id
  instance_id = aws_instance.mgmt[0].id
}

resource "aws_instance" "login" {
  count         = var.instances["login"]["count"]
  instance_type = var.instances["login"]["type"]
  ami           = var.image
  user_data = data.template_cloudinit_config.login_config[count.index].rendered

  subnet_id                   = aws_subnet.private_subnet.id
  key_name                    = aws_key_pair.key.key_name
  associate_public_ip_address = "true"

  vpc_security_group_ids = [
    aws_security_group.allow_in_services.id,
    aws_security_group.allow_any_inside_vpc.id,
    aws_security_group.allow_out_any.id,
  ]

  tags = {
    Name = format("login%02d", count.index + 1)
  }
}

resource "aws_instance" "node" {
  count         = var.instances["node"]["count"]
  instance_type = var.instances["node"]["type"]
  ami           = var.image

  user_data = data.template_cloudinit_config.node_config[count.index].rendered

  subnet_id                   = aws_subnet.private_subnet.id
  key_name                    = aws_key_pair.key.key_name
  associate_public_ip_address = "true"

  vpc_security_group_ids = [
    aws_security_group.allow_any_inside_vpc.id,
    aws_security_group.allow_out_any.id,
  ]

  tags = {
    Name = "node${count.index + 1}"
  }
}

locals {
  mgmt01_ip   = aws_instance.mgmt[0].private_ip
  public_ip   = aws_instance.login[0].public_ip
  cidr        = aws_subnet.private_subnet.cidr_block
  home_dev    = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? aws_volume_attachment.home[0].device_name : ""
  project_dev = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? aws_volume_attachment.project[0].device_name : ""
  scratch_dev = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? aws_volume_attachment.scratch[0].device_name : ""
}
