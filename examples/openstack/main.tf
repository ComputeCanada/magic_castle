terraform {
  required_version = ">= 0.12.21"
}

module "openstack" {
  source = "git::https://github.com/ComputeCanada/magic_castle.git//openstack"

  cluster_name = "workshop_km"
  domain       = "brune"
  image        = "CentOS-7-x64-2019-07"
  nb_users     = 10
  puppetenv_git= "https://github.com/arshul/puppet-genpipes"

  instances = {
    mgmt  = { type = "p4-4gb", count = 1 },
    login = { type = "p1-0.75gb", count = 1 },
    node  = [
      { type = "c2-3.75gb-92", count = 1 },
    ]
  }

  storage = {
    type         = "nfs"
    home_size    = 50
    project_size = 25
    scratch_size = 25
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
#   sudoer_username  = module.openstack.sudoer_username
# }

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud"
#   email            = "you@example.com"
#   project          = "your-project-name"
#   zone_name        = "you-zone-name"
#   name             = module.openstack.cluster_name
#   domain           = module.openstack.domain
#   public_ip        = module.openstack.ip
#   login_ids        = module.openstack.login_ids
#   rsa_public_key   = module.openstack.rsa_public_key
#   sudoer_username  = module.openstack.sudoer_username
# }

# output "hostnames" {
#   value = module.dns.hostnames
# }
