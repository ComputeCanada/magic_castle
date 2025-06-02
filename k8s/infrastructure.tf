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
  config_git_url        = var.config_git_url
  config_version        = var.config_version
  sudoer_username       = var.sudoer_username
  public_keys           = var.public_keys
  domain_name           = module.design.domain_name
  bastion_tag           = "public"
  cluster_name          = var.cluster_name
  guest_passwd          = var.guest_passwd
  nb_users              = var.nb_users
  software_stack        = var.software_stack
  cloud_provider        = "k8s"
  cloud_region          = "local"
  skip_upgrade          = var.skip_upgrade
  puppetfile            = var.puppetfile
}

locals {
  inventory = { for x, values in module.design.instances :
    x => {
      public_ip = ""
      local_ip  = ""
      prefix    = values.prefix
      tags      = values.tags
      specs     = values.specs
      volumes = {}
    }
  }
}

resource "local_file" "instances" {
  for_each = module.design.instances_to_build
  filename = format("${path.cwd}/%s-%s.yaml", var.cluster_name, each.key)
  content  = module.configuration.user_data[each.key]
}

resource "local_file" "terraform_data" {
  filename = "${path.cwd}/terraform_data.yaml"
  content  = module.configuration.terraform_data
}
