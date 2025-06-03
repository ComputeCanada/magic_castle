terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.0"
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

resource "docker_image" "image" {
  name = var.image
}

resource "docker_container" "instances" {
  for_each = module.design.instances_to_build
  name  = each.key
  image = docker_image.image.image_id
  upload {
    file = "/etc/cloud/cloud.cfg.d/01_mc_config.cfg"
    content = <<EOT
datasource:
    NoCloud:
    user-data: |
      ${indent(6, module.configuration.user_data[each.key])}
EOT
  }
  upload {
    file = "/usr/bin/start-mc"
    content = <<EOT
#/bin/bash
dnf install -y cloud-init
cloud-init --all-stages
EOT
    executable = true
  }
#   command = ["cloud-init", "modules", "--mode", "final"]
    command = ["sleep", "3600"]
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
