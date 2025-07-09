terraform {
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "0.3.1"
    }
  }
}

module "design" {
  source         = "../common/design"
  cluster_name   = var.cluster_name
  domain         = var.domain
  instances      = var.instances
  min_disk_size  = 10
  pool           = var.pool
  volumes        = var.volumes
  firewall_rules = var.firewall_rules
}

module "configuration" {
  source                = "../common/configuration"
  inventory             = local.inventory
  post_inventory        = local.post_inventory
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
  cloud_provider        = "incus"
  cloud_region          = "local"
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
  for_each = toset([ for host, values in module.design.instances: lookup(values, "image", var.image) ])
  project  = incus_project.project.name
  source_image = {
    # TODO: figure out if what needs to happen to "remote" when using snapshot instead of remote images.
    remote = "images"
    name   = each.key
    # TODO: Figure out how choose between "container" and "virtual-machine"
    # type =
  }
}

resource "incus_instance" "instances" {
  for_each = module.design.instances_to_build

  project = incus_project.project.name
  name    = each.key
  image   = incus_image.image[lookup(each.value, "image", var.image)].fingerprint
  type    = each.value.type

  config = {
    "cloud-init.user-data" = module.configuration.user_data[each.key]
    "security.privileged"  = true
  }

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = incus_network.network.name
    }
  }

  device {
    type = "disk"
    name = "root"

    properties = {
      pool = "default"
      path = "/"
    }
  }

  dynamic "device" {
    for_each = var.forward_proxy && contains(each.value.tags, "proxy") ? { for name, rule in var.firewall_rules: name => rule if rule.tag == "proxy" } : {}
    content {
      name = device.key
      type = "proxy"
      properties = {
        listen = "${device.value.protocol}:0.0.0.0:${device.value.from_port}"
        connect = "${device.value.protocol}:127.0.0.1:${device.value.to_port}"
      }
    }
  }

  wait_for {
    type = "ipv4"
  }
}

locals {
  inventory = { for x, values in module.design.instances :
    x => {
      prefix    = values.prefix
      tags      = values.tags
      specs     = values.specs
      volumes = {}
    }
  }

  post_inventory = { for host, values in local.inventory:
    host => merge(values, {
      local_ip  = try(incus_instance.instances[host].ipv4_address, "")
      public_ip = try(incus_instance.instances[host].ipv4_address, "")
    })
  }

  public_instances = { for host, values in module.configuration.inventory: host => values if contains(values.tags, "public")}
}

output "project" {
  value = incus_project.project.name
}
