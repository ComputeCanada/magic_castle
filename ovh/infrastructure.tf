provider "openstack" {
}

resource "openstack_compute_secgroup_v2" "secgroup" {
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

resource "openstack_networking_network_v2" "network" {
  name = "${var.cluster_name}_network"
}

resource "openstack_networking_subnet_v2" "subnet" {
  name        = "${var.cluster_name}_subnet"
  network_id  = openstack_networking_network_v2.network.id
  ip_version  = 4
  cidr        = "10.0.1.0/24"
  no_gateway  = true
  enable_dhcp = true
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "slurm_cloud_key"
  public_key = file(var.public_key_path)
}

resource "openstack_blockstorage_volume_v2" "home" {
  name        = "${var.cluster_name}_home"
  description = "${var.cluster_name} /home"
  size        = var.home_size
}

resource "openstack_blockstorage_volume_v2" "project" {
  name        = "${var.cluster_name}_project"
  description = "${var.cluster_name} /project"
  size        = var.project_size
}

resource "openstack_blockstorage_volume_v2" "scratch" {
  name        = "${var.cluster_name}_scratch"
  description = "${var.cluster_name} /scratch"
  size        = var.scratch_size
}

resource "openstack_compute_instance_v2" "mgmt" {
  count           = var.nb_mgmt
  name            = format("mgmt%02d", count.index + 1)
  image_id        = data.openstack_images_image_v2.image.id
  flavor_name     = var.os_flavor_mgmt
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = [openstack_compute_secgroup_v2.secgroup.name]
  user_data = element(
    data.template_cloudinit_config.mgmt_config.*.rendered,
    count.index,
  )

  # Networks must be defined in this order
  network {
    name = openstack_networking_network_v2.network.name
  }
  network {
    access_network = true
    name           = var.os_external_network
  }
}

resource "openstack_compute_volume_attach_v2" "va_home" {
  count       = var.nb_mgmt > 0 ? 1 : 0
  instance_id = openstack_compute_instance_v2.mgmt[0].id
  volume_id   = openstack_blockstorage_volume_v2.home.id
}

resource "openstack_compute_volume_attach_v2" "va_project" {
  count       = var.nb_mgmt > 0 ? 1 : 0
  instance_id = openstack_compute_instance_v2.mgmt[0].id
  volume_id   = openstack_blockstorage_volume_v2.project.id
  depends_on  = [openstack_compute_volume_attach_v2.va_home]
}

resource "openstack_compute_volume_attach_v2" "va_scratch" {
  count       = var.nb_mgmt > 0 ? 1 : 0
  instance_id = openstack_compute_instance_v2.mgmt[0].id
  volume_id   = openstack_blockstorage_volume_v2.scratch.id
  depends_on  = [openstack_compute_volume_attach_v2.va_project]
}

resource "openstack_compute_instance_v2" "login" {
  count    = var.nb_login
  name     = format("login%02d", count.index + 1)
  image_id = var.os_image_id

  flavor_name     = var.os_flavor_login
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = [openstack_compute_secgroup_v2.secgroup.name]
  user_data = element(
    data.template_cloudinit_config.login_config.*.rendered,
    count.index,
  )

  # Networks must be defined in this order
  network {
    name = openstack_networking_network_v2.network.name
  }
  network {
    access_network = true
    name           = var.os_external_network
  }
}

resource "openstack_compute_instance_v2" "node" {
  count    = var.nb_nodes
  name     = "node${count.index + 1}"
  image_id = var.os_image_id

  flavor_name     = var.os_flavor_node
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = [openstack_compute_secgroup_v2.secgroup.name]
  user_data = element(
    data.template_cloudinit_config.node_config.*.rendered,
    count.index,
  )

  network {
    name = openstack_networking_network_v2.network.name
  }
  network {
    access_network = true
    name           = var.os_external_network
  }
}

locals {
  mgmt01_ip   = openstack_compute_instance_v2.mgmt[0].network[0].fixed_ip_v4
  public_ip   = openstack_compute_instance_v2.login[0].network[1].fixed_ip_v4
  cidr        = openstack_networking_subnet_v2.subnet.cidr
  home_dev    = "/dev/vdb"
  project_dev = "/dev/vdc"
  scratch_dev = "/dev/vdd"
}
