provider "openstack" {}


data "openstack_networking_network_v2" "ext_network" {
  external = "True"
}

data "openstack_networking_network_v2" "int_network" {
  external = "False"
}

data "openstack_networking_subnet_v2" "subnet" {}

data "openstack_images_image_v2" "image" {
  name = "${var.os_image_name}"
}

data "openstack_compute_flavor_v2" "mgmt" {
  name = "${var.os_flavor_mgmt}"
}

data "openstack_compute_flavor_v2" "login" {
  name = "${var.os_flavor_login}"
}

data "openstack_compute_flavor_v2" "node" {
  name = "${var.os_flavor_node}"
}

data "external" "openstack_token" {
  program = ["sh", "${path.module}/gen_auth_token.sh"]
}

resource "openstack_compute_secgroup_v2" "secgroup_1" {
  name        = "${var.cluster_name}_secgroup"
  description = "Slurm+JupyterHub security group"

  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    self        = true
  }

  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "tcp"
    self        = true
  }

  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "udp"
    self        = true
  }

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "206.87.0.0/16"
  }

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # Globus
  rule {
    from_port   = 2811
    to_port     = 2811
    ip_protocol = "tcp"
    cidr        = "54.237.254.192/29"
  }

  rule {
    from_port   = 7512
    to_port     = 7512
    ip_protocol = "tcp"
    cidr        = "54.237.254.192/29"
  }

  rule {
    from_port   = 50000
    to_port     = 51000
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "${var.cluster_name}_key"
  public_key = "${file(var.public_key_path)}"
}

resource "openstack_networking_port_v2" "port_mgmt" {
  name               = "port_mgmt"
  network_id         = "${data.openstack_networking_network_v2.int_network.id}"
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_1.id}"]
  fixed_ip {
    subnet_id     = "${data.openstack_networking_subnet_v2.subnet.id}"
  }
}

resource "openstack_compute_instance_v2" "mgmt01" {
  name            = "mgmt01"
  flavor_id       = "${data.openstack_compute_flavor_v2.mgmt.id}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  user_data       = "${data.template_cloudinit_config.mgmt_config.rendered}"

  network {
    port = "${openstack_networking_port_v2.port_mgmt.id}"
  }

  block_device {
    uuid                  = "${data.openstack_images_image_v2.image.id}"
    source_type           = "image"
    volume_size           = "${var.shared_storage_size}"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
}

locals {
  mgmt01_ip = "${openstack_networking_port_v2.port_mgmt.all_fixed_ips.0}"
  public_ip = "${openstack_compute_floatingip_associate_v2.fip_1.floating_ip}"
}

resource "openstack_compute_instance_v2" "login01" {
  name     = "${var.cluster_name}01"
  image_id = "${data.openstack_images_image_v2.image.id}"

  flavor_id       = "${data.openstack_compute_flavor_v2.login.id}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.secgroup_1.name}"]
  user_data       = "${data.template_cloudinit_config.login_config.rendered}"
}

resource "openstack_compute_instance_v2" "node" {
  count    = "${var.nb_nodes}"
  name     = "node${count.index + 1}"
  image_id = "${data.openstack_images_image_v2.image.id}"

  flavor_id       = "${data.openstack_compute_flavor_v2.node.id}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.secgroup_1.name}"]
  user_data       = "${element(data.template_cloudinit_config.node_config.*.rendered, count.index)}"
}

resource "openstack_networking_floatingip_v2" "fip_1" {
  count = "${var.os_floating_ip == "" ? 1 : 0}"
  pool  = "${data.openstack_networking_network_v2.ext_network.name}"
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = "${var.os_floating_ip != "" ? var.os_floating_ip : element(concat(openstack_networking_floatingip_v2.fip_1.*.address, list("")), 0) }"
  instance_id = "${openstack_compute_instance_v2.login01.id}"
}
