terraform {
  required_version = ">= 0.14.2"
}

module "gcp" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//gcp?ref=tags"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "tags"

  cluster_name = "phoenix"
  domain       = "calculquebec.cloud"
  image        = "centos-7"
  nb_users     = 10

  instances = {
    mgmt   = { type = "n1-standard-2", tags = ["puppet", "mgmt", "nfs"], count = 1 }
    login  = { type = "n1-standard-2", tags = ["login", "public", "proxy"], count = 1 }
    node   = { type = "n1-standard-2", tags = ["node"], count = 1 }
    gpu    = { type = "n1-standard-2", count = 1, gpu_type = "nvidia-tesla-k80", gpu_count = 1 },
  }

  # Magic Castle's default root disk size is 10GB.
  # GCP requires at least 20GB of root disk.
  root_disk_size = 20

  volumes = {
    nfs = {
      home     = { size = 10 }
      project  = { size = 50 }
      scratch  = { size = 50 }
    }
  }

  public_keys = [file("~/.ssh/id_rsa.pub")]

  # Shared password, randomly chosen if blank
  guest_passwd = ""

  # GCP specifics
  project = "calcul-quebec-249013"
  region  = "us-central1"
}

## Uncomment to register your domain name with CloudFlare
module "dns" {
  source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare?ref=tags"
  email            = "you@example.com"
  name             = module.gcp.cluster_name
  domain           = module.gcp.domain
  public_instances = module.gcp.public_instances
  ssh_private_key  = module.gcp.ssh_private_key
  sudoer_username  = module.gcp.sudoer_username
}

# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud"
#   email            = "you@example.com"
#   project          = "your-project-id"
#   zone_name        = "your-zone-name"
#   name             = module.gcp.cluster_name
#   domain           = module.gcp.domain
#   public_ip        = module.gcp.ip
#   login_ids        = module.gcp.login_ids
#   rsa_public_key   = module.gcp.rsa_public_key
#   ssh_private_key  = module.gcp.ssh_private_key
#   sudoer_username  = module.gcp.sudoer_username
# }

# output "hostnames" {
# 	value = module.dns.hostnames
# }
