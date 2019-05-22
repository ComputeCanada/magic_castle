# Configure the AWS Provider
provider "aws" {
  region = "${var.region}"
}

# Network
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "vpc"
  }
}

# Internet gateway to give our VPC access to the outside world
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

# Grant the VPC internet access by creating a very generic
# destination CIDR ("catch all" - the least specific possible) 
# such that we route traffic to outside as a last resource for 
# any route that the table doesn't know about.
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.0.0/24"

  tags {
    Name = "vpc-subnet"
  }
}

resource "aws_security_group" "allow_out_any" {
  name   = "allow_out_any"
  vpc_id = "${aws_vpc.vpc.id}"

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
  vpc_id      = "${aws_vpc.vpc.id}"

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

  vpc_id = "${aws_vpc.vpc.id}"

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
resource "aws_instance" "mgmt" {
  count                       = "${var.nb_mgmt}"
  instance_type               = "${var.instance_type_mgmt}"
  ami                         = "ami-dcad28b8" # CentOS 7 -  ca-central-1
  user_data                   = "${element(data.template_cloudinit_config.mgmt_config.*.rendered, count.index)}"
  subnet_id                   = "${aws_subnet.private_subnet.id}"
  key_name                    = "${aws_key_pair.key.key_name}"
  associate_public_ip_address = "true"

  vpc_security_group_ids = [
    "${aws_security_group.allow_any_inside_vpc.id}",
    "${aws_security_group.allow_out_any.id}",
  ]

  tags {
    Name = "${format("mgmt%02d", count.index + 1)}"
  }
}

resource "aws_ebs_volume" "home" {
  availability_zone = "${var.availability_zone}"
  size              = "${var.home_size}"
  type              = "gp2"
  tags = {
    Name = "home"
  }
}

resource "aws_ebs_volume" "project" {
  availability_zone = "${var.availability_zone}"
  size              = "${var.project_size}"
  type              = "gp2"
  tags = {
    Name = "project"
  }
}

resource "aws_ebs_volume" "scratch" {
  availability_zone = "${var.availability_zone}"
  size              = "${var.scratch_size}"
  type              = "gp2"
  tags = {
    Name = "scratch"
  }
}

resource "aws_volume_attachment" "home" {
  count       = "${var.nb_mgmt > 0 ? 1 : 0}"
  device_name = "/dev/sdb"
  volume_id   = "${aws_ebs_volume.home.id}"
  instance_id = "${aws_instance.mgmt.0.id}"
}

resource "aws_volume_attachment" "project" {
  count       = "${var.nb_mgmt > 0 ? 1 : 0}"
  device_name = "/dev/sdc"
  volume_id   = "${aws_ebs_volume.project.id}"
  instance_id = "${aws_instance.mgmt.0.id}"
}

resource "aws_volume_attachment" "scratch" {
  count       = "${var.nb_mgmt > 0 ? 1 : 0}"
  device_name = "/dev/sdd"
  volume_id   = "${aws_ebs_volume.scratch.id}"
  instance_id = "${aws_instance.mgmt.0.id}"
}

resource "aws_instance" "login" {
  count                       = "${var.nb_login}"
  instance_type               = "${var.instance_type_login}"
  ami                         = "ami-dcad28b8" # CentOS 7 -  ca-central-1
  user_data                   = "${element(data.template_cloudinit_config.login_config.*.rendered, count.index)}"
  subnet_id                   = "${aws_subnet.private_subnet.id}"
  key_name                    = "${aws_key_pair.key.key_name}"
  associate_public_ip_address = "true"

  vpc_security_group_ids = [
    "${aws_security_group.allow_in_ssh.id}",
    "${aws_security_group.allow_any_inside_vpc.id}",
    "${aws_security_group.allow_out_any.id}",
  ]

  tags {
    Name = "${format("login%02d", count.index + 1)}"
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
  mgmt01_ip = "${aws_instance.mgmt.0.private_ip}"
  public_ip = "${aws_instance.login.0.public_ip}"
  cidr      = "${aws_subnet.private_subnet.cidr_block}"
  home_dev  = "${aws_volume_attachment.home.device_name}"
  project_dev = "${aws_volume_attachment.project.device_name}"
  scratch_dev = "${aws_volume_attachment.scratch.device_name}"
}
