terraform {
  required_version = ">= 0.12"
}

module "aws" {
  source = "git::ssh://gitlab@git.computecanada.ca/magic_castle/slurm_cloud.git//aws"

  cluster_name = "phoenix"
  domain       = "calculquebec.cloud"
  image        = "ami-dcad28b8" # CentOS 7 -  ca-central-1
  nb_users     = 10

  instances = {
    mgmt  = { type = "t2.medium", count = 1 },
    login = { type = "t2.medium", count = 1 },
    node  = { type = "t2.small",  count = 1 }
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

  # AWS specifics
  region            = "ca-central-1"
  availability_zone = "ca-central-1a"
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
#   source           = "git::ssh://gitlab@git.computecanada.ca/magic_castle/slurm_cloud.git//dns/cloudflare"
#   name             = module.aws.cluster_name
#   domain           = module.aws.domain
#   public_ip        = module.aws.ip
#   rsa_public_key   = module.aws.rsa_public_key
#   sudoer_username  = module.aws.sudoer_username
# }
# output "hostnames" {
# 	value = module.dns.hostnames
# }
