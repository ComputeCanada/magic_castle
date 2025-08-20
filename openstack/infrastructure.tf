module "design" {
  source         = "../common/design"
  cluster_name   = var.cluster_name
  domain         = var.domain
  image          = var.image
  instances      = var.instances
  min_disk_size  = 10
  pool           = var.pool
  volumes        = var.volumes
  firewall_rules = var.firewall_rules
}

module "configuration" {
  source          = "../common/configuration"
  inventory       = local.inventory
  post_inventory  = local.post_inventory
  config_git_url  = var.config_git_url
  config_version  = var.config_version
  sudoer_username = var.sudoer_username
  public_keys     = var.public_keys
  domain_name     = module.design.domain_name
  bastion_tag     = module.design.bastion_tag
  cluster_name    = var.cluster_name
  guest_passwd    = var.guest_passwd
  nb_users        = var.nb_users
  software_stack  = var.software_stack
  cloud_provider  = local.cloud_provider
  cloud_region    = local.cloud_region
  skip_upgrade    = var.skip_upgrade
  puppetfile      = var.puppetfile
}

module "provision" {
  source        = "../common/provision"
  configuration = module.configuration
  hieradata     = var.hieradata
  hieradata_dir = var.hieradata_dir
  eyaml_key     = var.eyaml_key
  puppetfile    = var.puppetfile
  depends_on = [
    local.network_provision_dep,
    openstack_compute_instance_v2.instances,
  ]
}

data "openstack_images_image_v2" "image" {
  for_each    = toset([for key, values in module.design.instances : values.image])
  name_regex  = each.key
  most_recent = true
}

data "openstack_compute_flavor_v2" "flavors" {
  for_each = toset([for key, values in module.design.instances : values.type])
  name     = each.key
}

resource "openstack_compute_instance_v2" "instances" {
  for_each = module.design.instances_to_build
  name     = format("%s-%s", var.cluster_name, each.key)
  image_id = each.value.disk_size > data.openstack_compute_flavor_v2.flavors[each.value.type].disk ? null : data.openstack_images_image_v2.image[each.value.image].id

  flavor_name  = each.value.type
  user_data    = base64gzip(module.configuration.user_data[each.key])
  metadata     = {}
  force_delete = true

  network {
    port = openstack_networking_port_v2.nic[each.key].id
  }
  dynamic "network" {
    for_each = local.ext_networks
    content {
      port = openstack_networking_port_v2.public_nic[each.key].id
    }
  }

  dynamic "block_device" {
    for_each = each.value.disk_size > data.openstack_compute_flavor_v2.flavors[each.value.type].disk ? [{ volume_size = each.value.disk_size }] : []
    content {
      uuid                  = data.openstack_images_image_v2.image[each.value.image].id
      source_type           = "image"
      destination_type      = "volume"
      boot_index            = 0
      delete_on_termination = true
      volume_size           = block_device.value.volume_size
      volume_type           = lookup(each.value, "disk_type", null)
    }
  }

  lifecycle {
    ignore_changes = [
      image_id,
      block_device[0].uuid,
      user_data,
    ]
  }
}

resource "openstack_blockstorage_volume_v3" "volumes" {
  for_each = {
    for x, values in module.design.volumes : x => values if lookup(values, "managed", true)
  }
  name                 = "${var.cluster_name}-${each.key}"
  description          = "${var.cluster_name} ${each.key}"
  size                 = each.value.size
  volume_type          = lookup(each.value, "type", null)
  snapshot_id          = lookup(each.value, "snapshot", null)
  enable_online_resize = lookup(each.value, "enable_resize", false)
}

data "openstack_blockstorage_volume_v3" "existing_volumes" {
  for_each = {
    for x, values in module.design.volumes : x => values if !lookup(values, "managed", true)
  }
  name = "${var.cluster_name}-${each.key}"
}

locals {
  volume_ids = {
    for key, values in module.design.volumes :
    key => lookup(values, "managed", true) ? openstack_blockstorage_volume_v3.volumes[key].id : data.openstack_blockstorage_volume_v3.existing_volumes[key].id
  }
}

resource "openstack_compute_volume_attach_v2" "attachments" {
  for_each    = module.design.volumes
  instance_id = openstack_compute_instance_v2.instances[each.value.instance].id
  volume_id   = local.volume_ids[each.key]
}

locals {
  inventory = { for x, values in module.design.instances :
    x => {
      public_ip = contains(values.tags, "public") ? local.public_ip[x] : ""
      local_ip  = openstack_networking_port_v2.nic[x].all_fixed_ips[0]
      prefix    = values.prefix
      tags      = values.tags
      specs = merge({
        cpus = data.openstack_compute_flavor_v2.flavors[values.type].vcpus
        ram  = data.openstack_compute_flavor_v2.flavors[values.type].ram
        gpus = sum([
          parseint(lookup(data.openstack_compute_flavor_v2.flavors[values.type].extra_specs, "resources:VGPU", "0"), 10),
          parseint(split(":", lookup(data.openstack_compute_flavor_v2.flavors[values.type].extra_specs, "pci_passthrough:alias", "gpu:0"))[1], 10)
        ])
      }, values.specs)
      volumes = contains(keys(module.design.volume_per_instance), x) ? {
        for pv_key, pv_values in var.volumes :
        pv_key => {
          for name, specs in pv_values :
          name => merge(
            { glob = "/dev/disk/by-id/*${substr(local.volume_ids["${x}-${pv_key}-${name}"], 0, 20)}" },
            specs,
          )
        } if contains(values.tags, pv_key)
      } : {}
    }
  }

  post_inventory = { for host, values in local.inventory :
    host => merge(values, {
      id = try(openstack_compute_instance_v2.instances[host].id, "")
    })
  }
}
