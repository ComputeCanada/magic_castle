provider "openstack" {}

resource "openstack_compute_secgroup_v2" "secgroup_1" {
  name        = "slurm_cloud"
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
    cidr        = "132.203.0.0/16"
  }

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "132.219.0.0/16"
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
}

resource "openstack_networking_network_v2" "network_1" {
  name = "network_1"
}

resource "openstack_networking_subnet_v2" "subnet" {
  name        = "subnet"
  network_id  = "${openstack_networking_network_v2.network_1.id}"
  ip_version  = 4
  cidr        = "10.0.1.0/24"
  no_gateway  = true
  enable_dhcp = true
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "slurm_cloud_key"
  public_key = "${file(var.public_key_path)}"
}

resource "openstack_compute_instance_v2" "mgmt01" {
  name            = "mgmt"
  flavor_name     = "${var.os_flavor_mgmt}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.secgroup_1.name}"]
  user_data       = "${data.template_cloudinit_config.mgmt_config.rendered}"
  # Networks must be defined in this order
  network =
  {
    name = "${openstack_networking_network_v2.network_1.name}"
  }
  network =
  {
    access_network = true
    name           = "${var.os_external_network}"
  }
  block_device {
    uuid                  = "${var.os_image_id}"
    source_type           = "image"
    volume_size           = "${var.shared_storage_size}"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
}

resource "openstack_compute_instance_v2" "login01" {
  name     = "${var.cluster_name}01"
  image_id = "${var.os_image_id}"

  flavor_name       = "${var.os_flavor_login}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.secgroup_1.name}"]
  user_data       = "${data.template_cloudinit_config.login_config.rendered}"
  # Networks must be defined in this order
  network =
  {
    name = "${openstack_networking_network_v2.network_1.name}"
  }
  network =
  {
    access_network = true
    name           = "${var.os_external_network}"
  }
}

resource "openstack_compute_instance_v2" "node" {
  count    = "${var.nb_nodes}"
  name     = "node${count.index + 1}"
  image_id = "${var.os_image_id}"

  flavor_name     = "${var.os_flavor_node}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.secgroup_1.name}"]
  user_data       = "${element(data.template_cloudinit_config.node_config.*.rendered, count.index)}"
  network =
  {
    name = "${openstack_networking_network_v2.network_1.name}"
  }
  network =
  {
    access_network = true
    name           = "${var.os_external_network}"
  }
}

locals {
  mgmt01_ip = "${openstack_compute_instance_v2.mgmt01.network.0.fixed_ip_v4}"
  public_ip = "${openstack_compute_instance_v2.login01.network.1.fixed_ip_v4}"
  cidr      = "${openstack_networking_subnet_v2.subnet.cidr}"
}
