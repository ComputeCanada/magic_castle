# Configure the AWS Provider
provider "aws" {
  region = "${var.region}"
}

# Network
resource "aws_vpc" "vpc01" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "vpc01"
  }
}

# Internet gateway to give our VPC access to the outside world
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc01.id}"
}

# Grant the VPC internet access by creating a very generic
# destination CIDR ("catch all" - the least specific possible) 
# such that we route traffic to outside as a last resource for 
# any route that the table doesn't know about.
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.vpc01.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = "${aws_vpc.vpc01.id}"
  cidr_block = "10.0.0.0/24"

  tags {
    Name = "vpc01-subnet01"
  }
}

resource "aws_security_group" "allow_out_any" {
  name   = "allow_out_any"
  vpc_id = "${aws_vpc.vpc01.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_in_ssh" {
  name = "allow_in_ssh"

  description = "Allows SSH traffic into instances"
  vpc_id      = "${aws_vpc.vpc01.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_in_ssh"
  }
}

resource "aws_security_group" "allow_any_inside_vpc" {
  name = "allow_any_inside_vpc"

  vpc_id = "${aws_vpc.vpc01.id}"

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

  tags {
    Name = "allow_any_inside_vpc"
  }
}

resource "aws_key_pair" "key" {
  key_name   = "slurm-cloud-key"
  public_key = "${file(var.public_key_path)}"
}

# Instances
resource "aws_instance" "mgmt01" {
  instance_type               = "${var.instance_type_mgmt}"
  ami                         = "ami-dcad28b8"                                           # CentOS 7 -  ca-central-1
  user_data                   = "${data.template_cloudinit_config.mgmt_config.rendered}"
  subnet_id                   = "${aws_subnet.private_subnet.id}"
  key_name                    = "${aws_key_pair.key.key_name}"
  associate_public_ip_address = "true"

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.shared_storage_size}"
  }

  vpc_security_group_ids = [
    "${aws_security_group.allow_any_inside_vpc.id}",
    "${aws_security_group.allow_out_any.id}",
  ]

  tags {
    Name = "mgmt01"
  }
}

resource "aws_instance" "login01" {
  instance_type               = "${var.instance_type_login}"
  ami                         = "ami-dcad28b8"                                            # CentOS 7 -  ca-central-1
  user_data                   = "${data.template_cloudinit_config.login_config.rendered}"
  subnet_id                   = "${aws_subnet.private_subnet.id}"
  key_name                    = "${aws_key_pair.key.key_name}"
  associate_public_ip_address = "true"

  vpc_security_group_ids = [
    "${aws_security_group.allow_in_ssh.id}",
    "${aws_security_group.allow_any_inside_vpc.id}",
    "${aws_security_group.allow_out_any.id}",
  ]

  tags {
    Name = "login01"
  }
}

resource "aws_instance" "node" {
  count = "${var.nb_nodes}"

  # CentOS 7 -  ca-central-1
  ami                         = "ami-dcad28b8"
  instance_type               = "${var.instance_type_node}"
  user_data                   = "${element(data.template_cloudinit_config.node_config.*.rendered, count.index)}"
  subnet_id                   = "${aws_subnet.private_subnet.id}"
  key_name                    = "${aws_key_pair.key.key_name}"
  associate_public_ip_address = "true"

  vpc_security_group_ids = [
    "${aws_security_group.allow_any_inside_vpc.id}",
    "${aws_security_group.allow_out_any.id}",
  ]

  tags {
    Name = "node${count.index + 1}"
  }
}

locals {
  mgmt01_ip = "${aws_instance.mgmt01.private_ip}"
  public_ip = "${aws_instance.login01.public_ip}"
  cidr      = "${aws_subnet.private_subnet.cidr_block}"
}
