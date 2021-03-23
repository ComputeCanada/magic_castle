provider "openstack" {
}

data "openstack_images_image_v2" "image" {
  name = var.image
}

data "openstack_compute_flavor_v2" "flavors" {
  for_each = local.instances
  name     = each.value.type
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "${var.cluster_name}-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "openstack_compute_secgroup_v2" "secgroup" {
  name        = "${var.cluster_name}-secgroup"
  description = "${var.cluster_name} security group"

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

resource "openstack_networking_port_v2" "ports" {
  for_each           = local.instances
  name               = format("%s-%s-port", var.cluster_name, each.key)
  network_id         = local.network.id
  security_group_ids = [openstack_compute_secgroup_v2.secgroup.id]
  fixed_ip {
    subnet_id = local.subnet.id
  }
}

locals {
  puppetmaster_ip = [for x, values in local.instances : openstack_networking_port_v2.ports[x].all_fixed_ips[0] if contains(values.tags, "puppet")]
}

resource "openstack_compute_instance_v2" "instances" {
  for_each = local.instances
  name     = format("%s-%s", var.cluster_name, each.key)
  image_id = var.root_disk_size > data.openstack_compute_flavor_v2.flavors[each.key].disk ? null : data.openstack_images_image_v2.image.id

  flavor_name = each.value.type
  key_pair    = openstack_compute_keypair_v2.keypair.name
  user_data   = base64gzip(local.user_data[each.key])

  network {
    port = openstack_networking_port_v2.ports[each.key].id
  }
  dynamic "network" {
    for_each = local.ext_networks
    content {
      access_network = network.value.access_network
      name           = network.value.name
    }
  }

  dynamic "block_device" {
    for_each = var.root_disk_size > data.openstack_compute_flavor_v2.flavors[each.key].disk ? [{ volume_size = var.root_disk_size }] : []
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
      block_device[0].uuid,
    ]
  }
}

locals {
  volumes = merge([
    for ki, vi in var.storage : {
      for kj, vj in vi :
      "${ki}-${kj}" => {
        size     = vj
        instance = try(element([for x, values in local.instances : x if contains(values.tags, ki)], 0), null)
      }
    }
  ]...)
}

resource "openstack_blockstorage_volume_v2" "volumes" {
  for_each    = local.volumes
  name        = "${var.cluster_name}-${each.key}"
  description = "${var.cluster_name} ${each.key}"
  size        = each.value.size
}

resource "openstack_compute_volume_attach_v2" "attachments" {
  for_each    = { for k, v in local.volumes : k => v if v.instance != null }
  instance_id = openstack_compute_instance_v2.instances[each.value.instance].id
  volume_id   = openstack_blockstorage_volume_v2.volumes[each.key].id
}

locals {
  volume_devices = {
    for ki, vi in var.storage :
    ki => {
      for kj, vj in vi :
      kj => ["/dev/disk/by-id/*${substr(openstack_blockstorage_volume_v2.volumes["${ki}-${kj}"].id, 0, 20)}"]
    }
  }
}

locals {
  puppetmaster_id = try(element([for x, values in local.instances : openstack_compute_instance_v2.instances[x].id if contains(values.tags, "puppet")], 0), "")
  all_instances = { for x, values in local.instances :
    x => {
      public_ip   = contains(values["tags"], "public") ? local.public_ip[x] : ""
      local_ip    = openstack_networking_port_v2.ports[x].all_fixed_ips[0]
      tags        = values["tags"]
      id          = openstack_compute_instance_v2.instances[x].id
      hostkeys    = {
        rsa = tls_private_key.rsa_hostkeys[local.host2prefix[x]].public_key_openssh
      }
    }
  }
}
