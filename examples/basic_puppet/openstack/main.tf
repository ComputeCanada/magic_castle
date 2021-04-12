terraform {
  required_version = ">= 0.14.2"
}

module "openstack" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//openstack?ref=tags"
  config_git_url = "https://github.com/MagicCastle/puppet-environment.git"
  config_version = "main"

  cluster_name = "dev"
  domain       = "calculquebec.cloud"
  image        = "CentOS-7-x64-2020-09"

  instances = {
    puppet = { type = "p4-7.5gb", tags = ["puppet"] }
    agent  = { type = "p2-3.75gb", tags = ["public"] }
  }

  volumes = { }

  public_keys = [file("~/.ssh/id_rsa.pub")]

  # OpenStack specific
  os_floating_ips = {}
}

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
