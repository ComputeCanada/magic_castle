provider "openstack" {
}

data "openstack_images_image_v2" "image" {
  name = var.image
}

data "openstack_compute_flavor_v2" "mgmt" {
  name = var.instances["mgmt"]["type"]
}

data "openstack_compute_flavor_v2" "login" {
  name = var.instances["login"]["type"]
}

data "openstack_compute_flavor_v2" "node" {
  name = var.instances["node"]["type"]
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

  dynamic "rule" {
    for_each = var.firewall_rules
    content {
      from_port   = rule.value.from_port
      to_port     = rule.value.to_port
      ip_protocol = rule.value.ip_protocol
      cidr        = rule.value.cidr
    }
  }
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "${var.cluster_name}_key"
  public_key = var.public_keys[0]
}

resource "openstack_blockstorage_volume_v2" "home" {
  count       = lower(var.storage["type"]) == "nfs" ? 1 : 0
  name        = "${var.cluster_name}_home"
  description = "${var.cluster_name} /home"
  size        = var.storage["home_size"]
}

resource "openstack_blockstorage_volume_v2" "project" {
  count       = lower(var.storage["type"]) == "nfs" ? 1 : 0
  name        = "${var.cluster_name}_project"
  description = "${var.cluster_name} /project"
  size        = var.storage["project_size"]
}

resource "openstack_blockstorage_volume_v2" "scratch" {
  count       = lower(var.storage["type"]) == "nfs" ? 1 : 0
  name        = "${var.cluster_name}_scratch"
  description = "${var.cluster_name} /scratch"
  size        = var.storage["scratch_size"]
}

resource "openstack_networking_port_v2" "port_mgmt" {
  count              = max(var.instances["mgmt"]["count"], 1)
  name               = format("port-mgmt%d", count.index + 1)
  network_id         = local.network.id
  security_group_ids = [openstack_compute_secgroup_v2.secgroup_1.id]
  fixed_ip {
    subnet_id = local.subnet.id
  }
}

resource "openstack_compute_instance_v2" "mgmt" {
  count    = var.instances["mgmt"]["count"]
  name     = format("mgmt%d", count.index + 1)
  image_id = var.root_disk_size > data.openstack_compute_flavor_v2.mgmt.disk ? null : data.openstack_images_image_v2.image.id

  flavor_name = var.instances["mgmt"]["type"]
  key_pair    = openstack_compute_keypair_v2.keypair.name
  user_data   = data.template_cloudinit_config.mgmt_config[count.index].rendered

  network {
    port = openstack_networking_port_v2.port_mgmt[count.index].id
  }
  dynamic "network" {
    for_each = local.ext_networks
    content {
      access_network = network.value.access_network
      name           = network.value.name
    }
  }

  dynamic "block_device" {
    for_each = var.root_disk_size > data.openstack_compute_flavor_v2.mgmt.disk ? [{volume_size = var.root_disk_size}] : []
    content {
      uuid                  = data.openstack_images_image_v2.image.id
      source_type           = "image"
      destination_type      = "volume"
      boot_index            = 0
      delete_on_termination = true
      volume_size           = block_device.value.volume_size
    }
  }

  lifecycle {
    ignore_changes = [
      image_id,
      block_device[0].uuid
    ]
  }
}

resource "openstack_compute_volume_attach_v2" "va_home" {
  count       = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? 1 : 0
  instance_id = openstack_compute_instance_v2.mgmt[0].id
  volume_id   = openstack_blockstorage_volume_v2.home[0].id
}

resource "openstack_compute_volume_attach_v2" "va_project" {
  count       = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? 1 : 0
  instance_id = openstack_compute_instance_v2.mgmt[0].id
  volume_id   = openstack_blockstorage_volume_v2.project[0].id
}

resource "openstack_compute_volume_attach_v2" "va_scratch" {
  count       = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? 1 : 0
  instance_id = openstack_compute_instance_v2.mgmt[0].id
  volume_id   = openstack_blockstorage_volume_v2.scratch[0].id
}

resource "openstack_networking_port_v2" "port_login" {
  count              = var.instances["login"]["count"]
  name               = format("port-login%d", count.index + 1)
  network_id         = local.network.id
  security_group_ids = [openstack_compute_secgroup_v2.secgroup_1.id]
  fixed_ip {
    subnet_id = local.subnet.id
  }
}

resource "openstack_compute_instance_v2" "login" {
  count    = var.instances["login"]["count"]
  name     = format("login%d", count.index + 1)
  image_id = var.root_disk_size > data.openstack_compute_flavor_v2.login.disk ? null : data.openstack_images_image_v2.image.id

  flavor_name     = var.instances["login"]["type"]
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = [openstack_compute_secgroup_v2.secgroup_1.name]
  user_data       = data.template_cloudinit_config.login_config[count.index].rendered

  network {
    port = openstack_networking_port_v2.port_login[count.index].id
  }
  dynamic "network" {
    for_each = local.ext_networks
    content {
      access_network = network.value.access_network
      name           = network.value.name
    }
  }

  dynamic "block_device" {
    for_each = var.root_disk_size > data.openstack_compute_flavor_v2.login.disk ? [{volume_size = var.root_disk_size}] : []
    content {
      uuid                  = data.openstack_images_image_v2.image.id
      source_type           = "image"
      destination_type      = "volume"
      boot_index            = 0
      delete_on_termination = true
      volume_size           = block_device.value.volume_size
    }
  }

  lifecycle {
    ignore_changes = [
      image_id,
      block_device[0].uuid
    ]
  }
}

resource "openstack_networking_port_v2" "port_node" {
  count              = var.instances["node"]["count"]
  name               = format("port-node%d", count.index + 1)
  network_id         = local.network.id
  security_group_ids = [openstack_compute_secgroup_v2.secgroup_1.id]
  fixed_ip {
    subnet_id = local.subnet.id
  }
}

resource "openstack_compute_instance_v2" "node" {
  count    = var.instances["node"]["count"]
  name     = "node${count.index + 1}"
  image_id = var.root_disk_size > data.openstack_compute_flavor_v2.node.disk ? null : data.openstack_images_image_v2.image.id

  flavor_name     = var.instances["node"]["type"]
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = [openstack_compute_secgroup_v2.secgroup_1.name]
  user_data       = data.template_cloudinit_config.node_config[count.index].rendered

  network {
    port = openstack_networking_port_v2.port_node[count.index].id
  }
  dynamic "network" {
    for_each = local.ext_networks
    content {
      access_network = network.value.access_network
      name           = network.value.name
    }
  }

  dynamic "block_device" {
    for_each = var.root_disk_size > data.openstack_compute_flavor_v2.node.disk ? [{volume_size = var.root_disk_size}] : []
    content {
      uuid                  = data.openstack_images_image_v2.image.id
      source_type           = "image"
      destination_type      = "volume"
      boot_index            = 0
      delete_on_termination = true
      volume_size           = block_device.value.volume_size
    }
  }

  lifecycle {
    ignore_changes = [
      image_id,
      block_device[0].uuid
    ]
  }
}

locals {
  mgmt1_ip    = openstack_networking_port_v2.port_mgmt[0].all_fixed_ips[0]
  home_dev    = "/dev/disk/by-id/*${substr(openstack_blockstorage_volume_v2.home[0].id, 0, 20)}"
  project_dev = "/dev/disk/by-id/*${substr(openstack_blockstorage_volume_v2.project[0].id, 0, 20)}"
  scratch_dev = "/dev/disk/by-id/*${substr(openstack_blockstorage_volume_v2.scratch[0].id, 0, 20)}"
}
