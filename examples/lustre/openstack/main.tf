terraform {
  required_version = ">= 0.14.2"
}

module "openstack" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//openstack?ref=tags"
  config_git_url = "https://github.com/MagicCastle/lustre-environment.git"
  config_version = "main"

  cluster_name = "lustre"
  domain       = "calculquebec.cloud"
  image        = "CentOS-7-x64-2020-09"

  instances = {
    puppet = { type = "p4-7.5gb", tags = ["puppet"] }
    mds    = { type = "p2-3.75gb", tags = ["mds"], count = 1 }
    oss    = { type = "p2-3.75gb", tags = ["oss"], count = 2 }
    login = { type = "p2-3.75gb", tags = ["public"], count = 1 }
  }

  storage = {
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

## Uncomment to register your domain name with CloudFlare
module "dns" {
  source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare?ref=tags"
  email            = "felix@calculquebec.ca"
  name             = module.openstack.cluster_name
  domain           = module.openstack.domain
  public_instances = module.openstack.public_instances
  ssh_private_key  = module.openstack.ssh_private_key
  sudoer_username  = module.openstack.sudoer_username
}

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud?ref=tags"
#   email            = "you@example.com"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.openstack.cluster_name
#   domain           = module.openstack.domain
#   public_instances = module.openstack.public_instances
#   ssh_private_key  = module.openstack.ssh_private_key
#   sudoer_username  = module.openstack.sudoer_username
# }

output "hostnames" {
  value = module.dns.hostnames
}
