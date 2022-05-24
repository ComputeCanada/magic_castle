terraform {
  required_version = ">= 1.1.0"
}

module "openstack" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//openstack"
  config_git_url = "https://github.com/MagicCastle/lustre-environment.git"
  config_version = "11.9.x"

  cluster_name = "lustre"
  domain       = "calculquebec.cloud"
  image        = "Rocky-8.5-x64-2021-11"

  instances = {
    puppet = { type = "p4-7.5gb", tags = ["puppet"] }
    mds    = { type = "p2-3.75gb", tags = ["mds"], count = 1 }
    oss    = { type = "p2-3.75gb", tags = ["oss"], count = 2 }
    login = { type = "p2-3.75gb", tags = ["public"], count = 1 }
  }

  volumes = {
    mds = {
      mdt0 = { size = 5 }
    }
    oss = {
      ost0 = { size = 5 }
      ost1 = { size = 5 }
    }
  }

  public_keys = [file("~/.ssh/id_rsa.pub")]
}

output "public_ip" {
  value = module.openstack.public_ip
}

output "sudoer" {
  value = module.openstack.accounts.sudoer
}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare"
#   email            = "you@example.com"
#   name             = module.openstack.cluster_name
#   domain           = module.openstack.domain
#   public_instances = module.openstack.public_instances
#   ssh_private_key  = module.openstack.ssh_private_key
#   sudoer_username  = module.openstack.accounts.sudoer.username
# }

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud"
#   email            = "you@example.com"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.openstack.cluster_name
#   domain           = module.openstack.domain
#   public_instances = module.openstack.public_instances
#   ssh_private_key  = module.openstack.ssh_private_key
#   sudoer_username  = module.openstack.accounts.sudoer.username
# }

# output "hostnames" {
#   value = module.dns.hostnames
# }
