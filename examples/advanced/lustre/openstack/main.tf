terraform {
  required_version = ">= 1.5.7"
}

module "openstack" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//openstack"
  config_git_url = "https://github.com/MagicCastle/lustre-environment.git"
  config_version = "main"

  cluster_name = "lustre"
  domain       = "calculquebec.cloud"
  image        = "Rocky-9"

  instances = {
    puppet = { type = "p4-7.5gb", tags = ["puppet"] }
    mds    = { type = "p2-3.75gb", tags = ["mds"], count = 1 }
    oss    = { type = "p2-3.75gb", tags = ["oss"], count = 2 }
    login = { type = "p2-3.75gb", tags = ["public"], count = 1 }
  }

  volumes = {
    mds = {
      mdt0 = { size = 5 }
    }
    oss = {
      ost0 = { size = 5 }
      ost1 = { size = 5 }
    }
  }

  public_keys = [file("~/.ssh/id_rsa.pub")]
}

output "public_ip" {
  value = module.openstack.public_ip
}

output "sudoer" {
  value = module.openstack.accounts.sudoer
}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare"
#   name             = module.openstack.cluster_name
#   domain           = module.openstack.domain
#   public_instances = module.openstack.public_instances
# }

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.openstack.cluster_name
#   domain           = module.openstack.domain
#   public_instances = module.openstack.public_instances
# }

# output "hostnames" {
#   value = module.dns.hostnames
# }
