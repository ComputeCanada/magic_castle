terraform {
  required_version = ">= 0.13.4"
}

module "openstack" {
  source = "git::https://github.com/ComputeCanada/magic_castle.git//openstack"

  cluster_name = "phoenix"
  domain       = "calculquebec.cloud"
  image        = "CentOS-7-x64-2019-07"
  nb_users     = 10

  instances = {
    mgmt  = { type = "p4-6gb", count = 1 },
    login = { type = "p2-3gb", count = 1 },
    node  = [
      { type = "p2-3gb", count = 1 },
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

  # OpenStack specific
  os_floating_ips = []
}

output "sudoer_username" {
  value = module.openstack.sudoer_username
}

output "guest_usernames" {
  value = module.openstack.guest_usernames
}

output "guest_passwd" {
  value = module.openstack.guest_passwd
}

output "public_ip" {
  value = module.openstack.ip
}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare"
#   email            = "you@example.com"
#   name             = module.openstack.cluster_name
#   domain           = module.openstack.domain
#   public_ip        = module.openstack.ip
#   login_ids        = module.openstack.login_ids
#   rsa_public_key   = module.openstack.rsa_public_key
#   ssh_private_key  = module.openstack.ssh_private_key
#   sudoer_username  = module.openstack.sudoer_username
# }

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud"
#   email            = "you@example.com"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.openstack.cluster_name
#   domain           = module.openstack.domain
#   public_ip        = module.openstack.ip
#   login_ids        = module.openstack.login_ids
#   rsa_public_key   = module.openstack.rsa_public_key
#   ssh_private_key  = module.openstack.ssh_private_key
#   sudoer_username  = module.openstack.sudoer_username
# }

# output "hostnames" {
#   value = module.dns.hostnames
# }
