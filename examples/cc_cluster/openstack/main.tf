terraform {
  required_version = ">= 0.13.4"
}

module "openstack" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//openstack?ref=tags"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "tags"

  cluster_name = "beluga"
  domain       = "calculquebec.cloud"
  image        = "CentOS-7-x64-2020-03"

  instances = {
    blg-puppet    = { type = "p4-6gb", tags = ["puppet"] }
    blg-slurmctld = { type = "p4-6gb", tags = ["mgmt", "nfs"], count = 1 }
    beluga        = { type = "p2-3gb", tags = ["login", "public", "proxy"], count = 1 }
    blg           = { type = "p2-3gb", tags = ["node"], count = 1 }
  }

  storage = {
    nfs = {
      home     = { size = 10, type = "volumes-ssd" }
      project  = { size = 50, type = "volumes-ssd" }
      scratch  = { size = 50, type = "volumes-ssd" }
    }
  }

  public_keys = [file("~/.ssh/id_rsa.pub")]

  nb_users = 10
  # Shared password, randomly chosen if blank
  guest_passwd = ""

  # OpenStack specific
  os_floating_ips = {}
}

#output "public_instances" {
#  value = module.openstack.public_instances
#}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare?ref=tags"
#   email            = "you@example.com"
#   name             = module.openstack.cluster_name
#   domain           = module.openstack.domain
#   public_instances = module.openstack.public_instances
#   ssh_private_key  = module.openstack.ssh_private_key
#   sudoer_username  = module.openstack.sudoer_username
# }

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

# output "hostnames" {
#   value = module.dns.hostnames
# }
