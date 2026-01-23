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
  bastion_tags   = var.bastion_tags
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
  bastion_tags    = module.design.bastion_tags
  cluster_name    = var.cluster_name
  guest_passwd    = var.guest_passwd
  nb_users        = var.nb_users
  software_stack  = var.software_stack
  cloud_provider  = "incus"
  cloud_region    = "local"
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
}

resource "random_id" "project_name" {
  byte_length = 7
}

resource "incus_project" "project" {
  name        = random_id.project_name.hex
  description = "Magic Castle cluster ${var.cluster_name}.${var.domain}"
  config = {
    "features.storage.volumes" = true
    "features.images"          = true
    "features.profiles"        = true
    "features.networks.zones"  = true
    "features.storage.buckets" = false
    "features.networks"        = false
  }
}

resource "incus_image" "image" {
  for_each = toset([for host, values in module.design.instances : values.image if endswith(values.image, "/cloud")])
  project  = incus_project.project.name
  source_image = {
    remote = "images"
    name   = each.key
    # TODO: Figure out how choose between "container" and "virtual-machine"
    # type =
  }
}

resource "incus_storage_volume" "filesystems" {
  for_each = toset(var.shared_filesystems)

  name         = each.key
  pool         = var.storage_pool
  content_type = "filesystem"
  description  = "${var.cluster_name}.${var.domain} ${each.key}"
  project      = random_id.project_name.hex
}

resource "incus_instance" "instances" {
  for_each = module.design.instances_to_build

  project = incus_project.project.name
  name    = each.key
  image   = try(incus_image.image[each.value.image].fingerprint, each.value.image)
  type    = each.value.type

  target = try(each.value.target, null)

  config = {
    "cloud-init.user-data" = module.configuration.user_data[each.key]
    "security.privileged"  = var.privileged
  }

  device {
    name = "eth0"
    type = "nic"

    properties = {
      network = incus_network.network.name
    }
  }

  device {
    type = "disk"
    name = "root"

    properties = {
      pool = var.storage_pool
      path = "/"
    }
  }

  dynamic "device" {
    for_each = incus_storage_volume.filesystems
    content {
      type = "disk"
      name = device.key
      properties = {
        pool   = var.storage_pool
        source = device.value.name
        path   = "/${device.key}"
      }
    }
  }

  dynamic "device" {
    for_each = var.forward_proxy && contains(each.value.tags, "proxy") ? { for name, rule in var.firewall_rules : name => rule if rule.tag == "proxy" } : {}
    content {
      name = device.key
      type = "proxy"
      properties = {
        listen  = "${device.value.protocol}:0.0.0.0:${device.value.from_port}"
        connect = "${device.value.protocol}:127.0.0.1:${device.value.to_port}"
      }
    }
  }

  wait_for {
    type = "ipv4"
  }
}

locals {
  inventory = { for host, values in module.design.instances :
    host => {
      prefix  = values.prefix
      tags    = values.tags
      specs   = values.specs
      volumes = {}
    }
  }

  post_inventory = { for host, values in local.inventory :
    host => merge(values, {
      local_ip  = try(incus_instance.instances[host].ipv4_address, ""),
      public_ip = try(incus_instance.instances[host].ipv4_address, ""),
    })
  }

  public_instances = { for host, values in module.configuration.inventory : host => values if contains(values.tags, "public") }
}

output "project" {
  value = incus_project.project.name
}
