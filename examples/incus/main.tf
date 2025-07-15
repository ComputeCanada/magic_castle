terraform {
  required_version = ">= 1.5.7"
}

module "incus" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//incus"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "main"

  cluster_name = "phoenix"
  domain       = "calculquebec.cloud"
  image        = "rockylinux/9/cloud"

  instances = {
    mgmt   = { type = "container", cpus = 4, ram = 6000, gpus = 0, tags = ["puppet", "mgmt", "nfs"], count = 1 }
    login  = { type = "container", cpus = 2, ram = 3000, gpus = 0, tags = ["login", "public", "proxy"], count = 1 }
    node   = { type = "container", cpus = 2, ram = 3000, gpus = 0, tags = ["node"], count = 1 }
  }

  volumes = {}

  public_keys = []
  hieradata = file("data.yaml")

  # Uncomment to run the containers without privileges
  #privileged = false
  #hieradata = file("unprivileged.yaml")

  nb_users = 10
  # Shared password, randomly chosen if blank
  guest_passwd = ""

  # Set to true to make port 80 and 443 of the proxy container forwarded on the host
  # There is a maximum of 1 cluster with forward_proxy = true per incus server.
  forward_proxy = false
}

output "accounts" {
  value = module.incus.accounts
}

output "project" {
  value = module.incus.project
}

output "public_ip" {
  value = module.incus.public_ip
}


# data "http" "agent_ip" {
#   url = "http://ipv4.icanhazip.com"
# }
# locals {
#   public_instances = { for host, values in module.incus.public_instances: host => merge(values, { "public_ip" = chomp(data.http.agent_ip.response_body) }) }
# }
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare"
#   name             = module.incus.cluster_name
#   domain           = module.incus.domain
#   public_instances = local.public_instances
# }
#
# output "hostnames" {
#   value = module.dns.hostnames
# }
