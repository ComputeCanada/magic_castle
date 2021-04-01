terraform {
  required_version = ">= 0.14.2"
}

module "aws" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//aws?ref=tags"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "tags"

  cluster_name = "phoenix"
  domain       = "calculquebec.cloud"
  image        = "ami-033e6106180a626d0" # CentOS 7 -  ca-central-1

  instances = {
    mgmt  = { type = "t3.large",  count = 1, tags = ["mgmt", "puppet"] },
    login = { type = "t3.medium", count = 1, tags = ["login", "public", "proxy"] },
    node  = { type = "t3.medium",  count = 1, tags = ["node"] }
  }

  storage = {
    nfs = {
      home     = { size = 10, type = "gp2" }
      project  = { size = 50, type = "gp2" }
      scratch  = { size = 50, type = "gp2" }
    }
  }

  public_keys = [file("~/.ssh/id_rsa.pub")]

  nb_users     = 10
  # Shared password, randomly chosen if blank
  guest_passwd = ""

  # AWS specifics
  region            = "ca-central-1"
}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare?ref=tags"
#   email            = "you@example.com"
#   name             = module.aws.cluster_name
#   domain           = module.aws.domain
#   public_instances = module.aws.public_instances
#   ssh_private_key  = module.aws.ssh_private_key
#   sudoer_username  = module.aws.sudoer_username
# }

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud?ref=tags"
#   email            = "you@example.com"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.aws.cluster_name
#   domain           = module.aws.domain
#   public_instances = module.aws.public_instances
#   ssh_private_key  = module.aws.ssh_private_key
#   sudoer_username  = module.aws.sudoer_username
# }

# output "hostnames" {
# 	value = module.dns.hostnames
# }
