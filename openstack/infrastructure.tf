provider "openstack" {
}

module "design" {
  source       = "../common/design"
  cluster_name = var.cluster_name
  domain       = var.domain
  instances    = var.instances
  volumes      = var.volumes
}

module "instance_config" {
  source           = "../common/instance_config"
  host_prefixes    = toset(keys(var.instances))
  instances        = module.design.instances
  config_git_url   = var.config_git_url
  config_version   = var.config_version
  puppetserver_ip  = local.puppetserver_ip
  sudoer_username  = var.sudoer_username
  public_keys      = var.public_keys
  host2prefix      = module.design.host2prefix
  generate_ssh_key = var.generate_ssh_key
}

module "cluster_config" {
  source          = "../common/cluster_config"
  instances       = local.all_instances
  nb_users        = var.nb_users
  hieradata       = var.hieradata
  software_stack  = var.software_stack
  cloud_provider  = local.cloud_provider
  cloud_region    = local.cloud_region
  sudoer_username = var.sudoer_username
  guest_passwd    = var.guest_passwd
  all_tags        = module.design.all_tags
  domain_name     = module.design.domain_name
  cluster_name    = var.cluster_name
  puppetserver_id = local.puppetserver_id
  volume_devices  = local.volume_devices
  private_ssh_key = module.instance_config.private_key
}

data "openstack_images_image_v2" "image" {
  name = var.image
}

data "openstack_compute_flavor_v2" "flavors" {
  for_each = module.design.instances
  name     = each.value.type
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "${var.cluster_name}-key"
  public_key = var.public_keys[0]
}

resource "openstack_compute_instance_v2" "instances" {
  for_each = module.design.instances
  name     = format("%s-%s", var.cluster_name, each.key)
  image_id = var.root_disk_size > data.openstack_compute_flavor_v2.flavors[each.key].disk ? null : data.openstack_images_image_v2.image.id

  flavor_name = each.value.type
  key_pair    = openstack_compute_keypair_v2.keypair.name
  user_data   = base64gzip(module.instance_config.user_data[each.key])

  network {
    port = openstack_networking_port_v2.nic[each.key].id
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

resource "openstack_blockstorage_volume_v3" "volumes" {
  for_each    = module.design.volumes
  name        = "${var.cluster_name}-${each.key}"
  description = "${var.cluster_name} ${each.key}"
  size        = each.value.size
  volume_type = lookup(each.value, "type", null)
  snapshot_id = lookup(each.value, "snapshot", null)
}

resource "openstack_compute_volume_attach_v2" "attachments" {
  for_each    = module.design.volumes
  instance_id = openstack_compute_instance_v2.instances[each.value.instance].id
  volume_id   = openstack_blockstorage_volume_v3.volumes[each.key].id
}

locals {
  volume_devices = {
    for ki, vi in var.volumes :
    ki => {
      for kj, vj in vi :
      kj => [for key, volume in module.design.volumes :
        "/dev/disk/by-id/*${substr(openstack_blockstorage_volume_v3.volumes["${volume["instance"]}-${ki}-${kj}"].id, 0, 20)}"
        if key == "${volume["instance"]}-${ki}-${kj}"
      ]
    }
  }
}

locals {
  puppetserver_id = try(element([for x, values in module.design.instances : openstack_compute_instance_v2.instances[x].id if contains(values.tags, "puppet")], 0), "")
  all_instances = { for x, values in module.design.instances :
    x => {
      public_ip = contains(values["tags"], "public") ? local.public_ip[x] : ""
      local_ip  = openstack_networking_port_v2.nic[x].all_fixed_ips[0]
      tags      = values["tags"]
      id        = openstack_compute_instance_v2.instances[x].id
      hostkeys = {
        rsa = module.instance_config.rsa_hostkeys[x]
      }
    }
  }
}
