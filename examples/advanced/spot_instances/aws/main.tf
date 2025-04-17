terraform {
  required_version = ">= 1.5.7"
}

module "aws" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//aws"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "main"

  cluster_name = "spot-aws"
  domain       = "calculquebec.cloud"
  # Rocky Linux 9.4 -  ca-central-1
  # https://rockylinux.org/download
  image        = "ami-07fbc9d69b1aa88b9"

  instances = {
    mgmt  = { type = "t3.large",  count = 1, tags = ["mgmt", "puppet", "nfs"] },
    login = { type = "t3.medium", count = 1, tags = ["login", "public", "proxy"] },
    node  = {
        tags       = ["node", "spot"],
        type       = "t3.medium",
        count      = 1,
        spot_price = 0.02
    }
  }

  volumes = {
    nfs = {
      home     = { size = 10, type = "gp2" }
      project  = { size = 50, type = "gp2" }
      scratch  = { size = 50, type = "gp2" }
    }
  }

  public_keys = [file("~/.ssh/id_rsa.pub")]

  nb_users     = 10

  # AWS specifics
  region            = "ca-central-1"
}

output "accounts" {
  value = module.aws.accounts
}

output "public_ip" {
  value = module.aws.public_ip
}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare"
#   name             = module.aws.cluster_name
#   domain           = module.aws.domain
#   public_instances = module.aws.public_instances
# }

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.aws.cluster_name
#   domain           = module.aws.domain
#   public_instances = module.aws.public_instances
# }

# output "hostnames" {
# 	value = module.dns.hostnames
# }
