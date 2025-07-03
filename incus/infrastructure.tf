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
  design                = module.design.instances
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

resource "incus_instance" "instances" {
  for_each = module.design.instances_to_build

  name  = each.key
  image = "images:${var.image}"
  type = each.value.type

  config = {
    "cloud-init.user-data" = module.configuration.user_data[each.key]
    "security.privileged"  = true
  }

  wait_for {
    type = "ipv4"
  }
}

locals {
  inventory = { for x, values in module.design.instances_to_build :
    x => {
      public_ip = incus_instance.instances[x].ipv4_address
      local_ip  = incus_instance.instances[x].ipv4_address
      prefix    = values.prefix
      tags      = values.tags
      specs     = values.specs
      volumes = {}
    }
  }

  public_instances = { for host, values in module.design.instances_to_build: host => values if contains(values.tags, "public")}
}
