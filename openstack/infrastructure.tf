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

resource "openstack_blockstorage_volume_v2" "home" {
  name        = "${var.cluster_name}_home"
  description = "${var.cluster_name} /home"
  size        = "${var.home_size}"
}

resource "openstack_blockstorage_volume_v2" "project" {
  name        = "${var.cluster_name}_project"
  description = "${var.cluster_name} /project"
  size        = "${var.project_size}"
}

resource "openstack_blockstorage_volume_v2" "scratch" {
  name        = "${var.cluster_name}_scratch"
  description = "${var.cluster_name} /scratch"
  size        = "${var.scratch_size}"
}

resource "openstack_networking_port_v2" "port_mgmt" {
  count              = "${max(var.nb_mgmt, 1)}"
  name               = "${format("port-mgmt%02d", count.index + 1)}"
  network_id         = "${data.openstack_networking_network_v2.int_network.id}"
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_1.id}"]
  fixed_ip {
    subnet_id     = "${data.openstack_networking_subnet_v2.subnet.id}"
  }
}

resource "openstack_compute_instance_v2" "mgmt" {
  count           = "${var.nb_mgmt}"
  name            = "${format("mgmt%02d", count.index + 1)}"
  image_id        = "${data.openstack_images_image_v2.image.id}"

  flavor_name     = "${var.os_flavor_mgmt}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  user_data       = "${element(data.template_cloudinit_config.mgmt_config.*.rendered, count.index)}"

  network {
    port = "${element(openstack_networking_port_v2.port_mgmt.*.id, count.index)}"
  }
}

resource "openstack_compute_volume_attach_v2" "va_home" {
  count       = "${var.nb_mgmt > 0 ? 1 : 0}"
  instance_id = "${openstack_compute_instance_v2.mgmt.0.id}"
  volume_id   = "${openstack_blockstorage_volume_v2.home.id}"
}

resource "openstack_compute_volume_attach_v2" "va_project" {
  count       = "${var.nb_mgmt > 0 ? 1 : 0}"
  instance_id = "${openstack_compute_instance_v2.mgmt.0.id}"
  volume_id   = "${openstack_blockstorage_volume_v2.project.id}"
  depends_on  = ["openstack_compute_volume_attach_v2.va_home"]
}

resource "openstack_compute_volume_attach_v2" "va_scratch" {
  count       = "${var.nb_mgmt > 0 ? 1 : 0}"
  instance_id = "${openstack_compute_instance_v2.mgmt.0.id}"
  volume_id   = "${openstack_blockstorage_volume_v2.scratch.id}"
  depends_on  = ["openstack_compute_volume_attach_v2.va_project"]
}

resource "openstack_compute_instance_v2" "login" {
  count    = "${var.nb_login}"
  name     = "${format("login%02d", count.index + 1)}"
  image_id = "${data.openstack_images_image_v2.image.id}"

  flavor_name     = "${var.os_flavor_login}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.secgroup_1.name}"]
  user_data       = "${element(data.template_cloudinit_config.login_config.*.rendered, count.index)}"
}

resource "openstack_compute_instance_v2" "node" {
  count    = "${var.nb_nodes}"
  name     = "node${count.index + 1}"
  image_id = "${data.openstack_images_image_v2.image.id}"

  flavor_name     = "${var.os_flavor_node}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.secgroup_1.name}"]
  user_data       = "${element(data.template_cloudinit_config.node_config.*.rendered, count.index)}"
}

resource "openstack_networking_floatingip_v2" "fip" {
  count = "${var.os_floating_ip == "" ? 1 : 0}"
  pool  = "${data.openstack_networking_network_v2.ext_network.name}"
}

resource "openstack_compute_floatingip_associate_v2" "fip" {
  count       = "${var.nb_login > 0 ? 1 : 0}"
  floating_ip = "${element(concat(openstack_networking_floatingip_v2.fip.*.address, list(var.os_floating_ip)), 0)}"
  instance_id = "${openstack_compute_instance_v2.login.0.id}"
}

locals {
  mgmt01_ip = "${openstack_networking_port_v2.port_mgmt.0.all_fixed_ips.0}"
  public_ip = "${element(concat(openstack_networking_floatingip_v2.fip.*.address, list(var.os_floating_ip)), 0)}"
  home_dev  = "/dev/vdb"
  project_dev  = "/dev/vdc"
  scratch_dev  = "/dev/vdd"
}
