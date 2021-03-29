terraform {
  required_version = ">= 0.13.4"
}

module "openstack" {
  source         = "../../../openstack"
  config_git_url = "https://github.com/MagicCastle/puppet-environment.git"
  config_version = "main"

  cluster_name = "lustre"
  domain       = "calculquebec.cloud"
  image        = "CentOS-7-x64-2020-09"

  instances = {
    puppet = { type = "p4-7.5gb", tags = ["puppet"] }
    mds    = { type = "p2-3.75gb", tags = ["mdt"], count = 1 }
    oss    = { type = "p2-3.75gb", tags = ["ost"], count = 1 }
    login = { type = "p2-3.75gb", tags = ["public"], count = 1 }
  }

  storage = {
    mdt = {
      mdt0 = { size = 5 }
      mdt1 = { size = 5 }
    }
    ost = {
      ost0 = { size = 5 }
      ost1 = { size = 5 }
    }
  }

  public_keys = [file("~/.ssh/id_rsa.pub")]

  nb_users = 10
  # Shared password, randomly chosen if blank
  guest_passwd = ""

  # OpenStack specific
  os_floating_ips = {}
}

#output "volume_per_instance" {
# value = module.openstack.volume_per_instance
#}

#output "public_instances" {
#  value = module.openstack.public_instances
#}

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
