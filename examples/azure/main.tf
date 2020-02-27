terraform {
  required_version = ">= 0.12"
}

module "azure" {
  source = "git::https://github.com/ComputeCanada/magic_castle.git//azure"

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

  nb_users     = 10

  instances = {
    mgmt  = { type = "Standard_DS2_v2", count = 1 },
    login = { type = "Standard_DS1_v2", count = 1 },
    node  = [
      { type = "Standard_DS1_v2", count = 1 },
    ]
  }

  storage = {
    type         = "nfs"
    home_size    = 100
    project_size = 50
    scratch_size = 50
  }

  public_keys = [file("~/.ssh/id_rsa.pub")]

  # Shared password, randomly chosen if blank
  guest_passwd = ""

  # Azure specifics
  location = "eastus"
}

output "sudoer_username" {
  value = module.azure.sudoer_username
}

output "guest_usernames" {
  value = module.azure.guest_usernames
}

output "guest_passwd" {
  value = module.azure.guest_passwd
}

output "public_ip" {
  value = module.azure.ip
}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare"
#   name             = module.azure.cluster_name
#   domain           = module.azure.domain
#   email            = "you@example.com"
#   public_ip        = module.azure.ip
#   rsa_public_key   = module.azure.rsa_public_key
#   sudoer_username  = module.azure.sudoer_username
# }

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud"
#   email            = "you@example.com"
#   project          = "your-project-name"
#   zone_name        = "you-zone-name"
#   name             = module.azure.cluster_name
#   domain           = module.azure.domain
#   public_ip        = module.azure.ip
#   rsa_public_key   = module.azure.rsa_public_key
#   sudoer_username  = module.azure.sudoer_username
# }


# output "hostnames" {
# 	value = module.dns.hostnames
# }
