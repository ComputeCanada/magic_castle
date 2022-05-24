terraform {
  required_version = ">= 1.1.0"
}

module "openstack" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//openstack"
  config_git_url = "https://github.com/MagicCastle/k8s-environment.git"
  config_version = "11.9.x"

  cluster_name = "k8s-os"
  domain       = "computecanada.dev"
  image        = "Rocky-8.5-x64-2021-11"

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

  # Magic Castle default firewall rules are too permissive
  # for this example. The following restricts it to SSH only.
  firewall_rules = [
    {"name"="SSH", "from_port"=22, "to_port"=22, "ip_protocol"="tcp", "cidr"="0.0.0.0/0"},
  ]
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
