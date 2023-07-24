terraform {
  required_version = ">= 1.4.0"
}

module "azure" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//azure"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "main"

  cluster_name = "spot-azure"
  domain       = "calculquebec.cloud"
  image        = {
    publisher = "OpenLogic",
    offer     = "CentOS-CI",
    sku       = "7-CI"
  }

  instances = {
    mgmt  = { type = "Standard_DS2_v2",  count = 1, tags = ["mgmt", "puppet", "nfs"] },
    login = { type = "Standard_DS1_v2", count = 1, tags = ["login", "public", "proxy"] },
    node  = {
        type          = "Standard_DS1_v2",
        count         = 1,
        tags          = ["node", "spot"],
        max_bid_price = 0.05
    }
  }

  volumes = {
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

output "accounts" {
  value = module.azure.accounts
}

output "public_ip" {
  value = module.azure.public_ip
}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare"
#   name             = module.azure.cluster_name
#   domain           = module.azure.domain
#   bastions         = module.azure.bastions
#   public_instances = module.azure.public_instances
#   ssh_private_key  = module.azure.ssh_private_key
#   sudoer_username  = module.azure.accounts.sudoer.username
# }

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.azure.cluster_name
#   domain           = module.azure.domain
#   bastions         = module.azure.bastions
#   public_instances = module.azure.public_instances
#   ssh_private_key  = module.azure.ssh_private_key
#   sudoer_username  = module.azure.accounts.sudoer.username
# }

# output "hostnames" {
# 	value = module.dns.hostnames
# }
