terraform {
  required_version = ">= 0.13.4"
}

module "aws" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//aws"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "master"

  cluster_name = "phoenix"
  domain       = "calculquebec.cloud"
  image        = "ami-033e6106180a626d0" # CentOS 7 -  ca-central-1

  instances = {
    mgmt  = { type = "t3.large",  count = 1 },
    login = { type = "t3.medium", count = 1 },
    node  = [{ type = "t3.medium",  count = 1 }]
  }

  storage = {
    type         = "nfs"
    home_size    = 100
    project_size = 50
    scratch_size = 50
  }

  public_keys = [file("~/.ssh/id_rsa.pub")]

  nb_users     = 10
  # Shared password, randomly chosen if blank
  guest_passwd = ""

  # AWS specifics
  region            = "ca-central-1"
}

output "sudoer_username" {
  value = module.aws.sudoer_username
}

output "guest_usernames" {
  value = module.aws.guest_usernames
}

output "guest_passwd" {
  value = module.aws.guest_passwd
}

output "public_ip" {
  value = module.aws.ip
}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare"
#   name             = module.aws.cluster_name
#   domain           = module.aws.domain
#   public_ip        = module.aws.ip
#   login_ids        = module.aws.login_ids
#   email            = "you@example.com"
#   rsa_public_key   = module.aws.rsa_public_key
#   ssh_private_key  = module.aws.ssh_private_key
#   sudoer_username  = module.aws.sudoer_username
# }

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud"
#   email            = "you@example.com"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.aws.cluster_name
#   domain           = module.aws.domain
#   public_ip        = module.aws.ip
#   login_ids        = module.aws.login_ids
#   rsa_public_key   = module.aws.rsa_public_key
#   ssh_private_key  = module.aws.ssh_private_key
#   sudoer_username  = module.aws.sudoer_username
# }

# output "hostnames" {
# 	value = module.dns.hostnames
# }
