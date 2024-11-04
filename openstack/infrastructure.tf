module "design" {
  source         = "../common/design"
  cluster_name   = var.cluster_name
  domain         = var.domain
  instances      = var.instances
  pool           = var.pool
  volumes        = var.volumes
  firewall_rules = var.firewall_rules
}

module "configuration" {
  source                = "../common/configuration"
  inventory             = local.inventory
  config_git_url        = var.config_git_url
  config_version        = var.config_version
  sudoer_username       = var.sudoer_username
  public_keys           = var.public_keys
  domain_name           = module.design.domain_name
  bastion_tag           = module.design.bastion_tag
  cluster_name          = var.cluster_name
  guest_passwd          = var.guest_passwd
  nb_users              = var.nb_users
  software_stack        = var.software_stack
  cloud_provider        = local.cloud_provider
  cloud_region          = local.cloud_region
  skip_upgrade          = var.skip_upgrade
  puppetfile            = var.puppetfile
}

module "provision" {
  source          = "../common/provision"
  bastions        = module.configuration.bastions
  puppetservers   = module.configuration.puppetservers
  tf_ssh_key      = module.configuration.ssh_key
  terraform_data  = module.configuration.terraform_data
  terraform_facts = module.configuration.terraform_facts
  hieradata       = var.hieradata
  hieradata_dir   = var.hieradata_dir
  eyaml_key       = var.eyaml_key
  puppetfile      = var.puppetfile
  depends_on      = [
    local.network_provision_dep,
    openstack_compute_instance_v2.instances,
  ]
}

data "openstack_images_image_v2" "image" {
  for_each    = var.instances
  name_regex  = lookup(each.value, "image", var.image)
  most_recent = true
}

data "openstack_compute_flavor_v2" "flavors" {
  for_each = var.instances
  name     = each.value.type
}

resource "openstack_compute_instance_v2" "instances" {
  for_each = module.design.instances_to_build
  name     = format("%s-%s", var.cluster_name, each.key)
  image_id = lookup(each.value, "disk_size", 10) > data.openstack_compute_flavor_v2.flavors[each.value.prefix].disk ? null : data.openstack_images_image_v2.image[each.value.prefix].id

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
    for_each = lookup(each.value, "disk_size", 10) > data.openstack_compute_flavor_v2.flavors[each.value.prefix].disk ? [{ volume_size = lookup(each.value, "disk_size", 10) }] : []
    content {
      uuid                  = data.openstack_images_image_v2.image[each.value.prefix].id
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
  for_each    = module.design.volumes
  name        = "${var.cluster_name}-${each.key}"
  description = "${var.cluster_name} ${each.key}"
  size        = each.value.size
  volume_type = lookup(each.value, "type", null)
  snapshot_id = lookup(each.value, "snapshot", null)
  enable_online_resize = lookup(each.value, "enable_resize", false)
}

resource "openstack_compute_volume_attach_v2" "attachments" {
  for_each    = module.design.volumes
  instance_id = openstack_compute_instance_v2.instances[each.value.instance].id
  volume_id   = openstack_blockstorage_volume_v3.volumes[each.key].id
}

locals {
  inventory = { for x, values in module.design.instances :
    x => {
      public_ip = contains(values.tags, "public") ? local.public_ip[x] : ""
      local_ip  = openstack_networking_port_v2.nic[x].all_fixed_ips[0]
      prefix    = values.prefix
      tags      = values.tags
      specs = {
        cpus   = data.openstack_compute_flavor_v2.flavors[values.prefix].vcpus
        ram    = data.openstack_compute_flavor_v2.flavors[values.prefix].ram
        gpus   = sum([
          parseint(lookup(data.openstack_compute_flavor_v2.flavors[values.prefix].extra_specs, "resources:VGPU", "0"), 10),
          parseint(split(":", lookup(data.openstack_compute_flavor_v2.flavors[values.prefix].extra_specs, "pci_passthrough:alias", "gpu:0"))[1], 10)
        ])
        mig    = lookup(values, "mig", null)
        shard  = lookup(values, "shard", null)
      }
      volumes = contains(keys(module.design.volume_per_instance), x) ? {
        for pv_key, pv_values in var.volumes:
          pv_key => {
            for name, specs in pv_values:
              name => merge(
                { glob = "/dev/disk/by-id/*${substr(openstack_blockstorage_volume_v3.volumes["${x}-${pv_key}-${name}"].id, 0, 20)}" },
                specs,
              )
          } if contains(values.tags, pv_key)
       } : {}
    }
  }

  public_instances = { for host in keys(module.design.instances_to_build):
    host => merge(module.configuration.inventory[host], {id=openstack_compute_instance_v2.instances[host].id})
    if contains(module.configuration.inventory[host].tags, "public")
  }
}
