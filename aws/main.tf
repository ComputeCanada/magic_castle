# Configure the AWS Provider
provider "aws" {
  region = "ca-central-1"
}

# Network
resource "aws_vpc" "vpc01" {
  cidr_block = "172.16.0.0/16"

  tags {
    Name = "vpc01"
  }
}

resource "aws_subnet" "subnet01" {
  vpc_id     = "${aws_vpc.vpc01.id}"
  cidr_block = "172.16.10.0/24"

  tags {
    Name = "vpc01-subnet01"
  }
}

# Instances
resource "aws_instance" "mgmt01" {
  instance_type = "t2.micro"
  ami           = "ami-dcad28b8"                                           # CentOS 7 -  ca-central-1
  user_data     = "${data.template_cloudinit_config.mgmt_config.rendered}"
  subnet_id     = "aws_subnet.subnet01"

  root_block_device {
    volume_type = "standard"
    volume_size = "20"
  }

  tags {
    Name = "mgmt01"
  }
}

locals {
  mgmt01_ip = "${aws_instance.mgmt01.private_ip}"
}
