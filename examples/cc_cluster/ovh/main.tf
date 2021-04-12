terraform {
  required_version = ">= 0.14.2"
}

module "ovh" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//ovh?ref=tags"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "tags"

  cluster_name = "phoenix"
  domain       = "calculquebec.cloud"
  image        = "CentOS-7-x64-2019-07"

  instances = {
    mgmt   = { type = "s1-2", tags = ["puppet", "mgmt", "nfs"], count = 1 }
    login  = { type = "s1-2", tags = ["login", "public", "proxy"], count = 1 }
    node   = { type = "s1-2", tags = ["node"], count = 1 }
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

}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare?ref=tags"
#   email            = "you@example.com"
#   name             = module.ovh.cluster_name
#   domain           = module.ovh.domain
#   public_instances = module.ovh.public_instances
#   ssh_private_key  = module.ovh.ssh_private_key
#   sudoer_username  = module.ovh.sudoer_username
# }

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud?ref=tags"
#   email            = "you@example.com"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.ovh.cluster_name
#   domain           = module.ovh.domain
#   public_instances = module.ovh.public_instances
#   ssh_private_key  = module.ovh.ssh_private_key
#   sudoer_username  = module.ovh.sudoer_username
# }

# output "hostnames" {
#   value = module.dns.hostnames
# }