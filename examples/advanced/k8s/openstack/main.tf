terraform {
  required_version = ">= 1.2.1"
}

module "openstack" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//openstack"
  config_git_url = "https://github.com/MagicCastle/k8s-environment.git"
  config_version = "main"

  cluster_name = "k8s-os"
  domain       = "computecanada.dev"
  image        = "Rocky-8.6-x64-2022-07"

  instances = {
    master   = { type = "c2-7.5gb-31", tags = ["controller", "puppet", "public"], count = 1 }
    replica  = { type = "c2-7.5gb-31", tags = ["controller"], count = 2 }
    node     = { type = "c2-7.5gb-31", tags = ["worker"], count = 5 }
  }

  volumes = {
    gfs = {
      data = { size = 100, type = "volumes-ssd" }
    }
  }

  public_keys = [file("~/.ssh/id_rsa.pub")]
}

output "public_ip" {
  value = module.openstack.public_ip
}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare"
#   email            = "you@example.com"
#   name             = module.openstack.cluster_name
#   domain           = module.openstack.domain
#   public_instances = module.openstack.public_instances
#   ssh_private_key  = module.openstack.ssh_private_key
#   sudoer_username  = module.openstack.accounts.sudoer.username
# }

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud"
#   email            = "you@example.com"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.openstack.cluster_name
#   domain           = module.openstack.domain
#   public_instances = module.openstack.public_instances
#   ssh_private_key  = module.openstack.ssh_private_key
#   sudoer_username  = module.openstack.accounts.sudoer.username
# }

# output "hostnames" {
#   value = module.dns.hostnames
# }
