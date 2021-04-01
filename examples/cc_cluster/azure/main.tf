terraform {
  required_version = ">= 0.14.2"
}

module "azure" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//azure?ref=tags"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "master"

  cluster_name = "phoenix"
  domain       = "calculquebec.cloud"
  image        = {
    publisher = "OpenLogic",
    offer     = "CentOS-CI",
    sku       = "7-CI"
  }
  # OpenLogic CentOS 7 images require at least 30GB of root disk.
  # Magic Castle default root disk size is 10GB.
  root_disk_size = 30

  instances = {
    mgmt  = { type = "Standard_DS2_v2",  count = 1, tags = ["mgmt", "puppet", "nfs"] },
    login = { type = "Standard_DS1_v2", count = 1, tags = ["login", "public", "proxy"] },
    node  = { type = "Standard_DS1_v2",  count = 1, tags = ["node"] }
  }

  storage = {
    nfs = {
      home     = { size = 10 }
      project  = { size = 50 }
      scratch  = { size = 50 }
    }
  }

  public_keys = [file("~/.ssh/id_rsa.pub")]

  nb_users     = 10
  # Shared password, randomly chosen if blank
  guest_passwd = ""

  # Azure specifics
  location = "eastus"
}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare?ref=tags"
#   email            = "you@example.com"
#   name             = module.azure.cluster_name
#   domain           = module.azure.domain
#   public_instances = module.azure.public_instances
#   ssh_private_key  = module.azure.ssh_private_key
#   sudoer_username  = module.azure.sudoer_username
# }

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud?ref=tags"
#   email            = "you@example.com"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.azure.cluster_name
#   domain           = module.azure.domain
#   public_instances = module.azure.public_instances
#   ssh_private_key  = module.azure.ssh_private_key
#   sudoer_username  = module.azure.sudoer_username
# }


# output "hostnames" {
# 	value = module.dns.hostnames
# }
