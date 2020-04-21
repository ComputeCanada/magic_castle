terraform {
  required_version = ">= 0.12.21"
}

module "gcp" {
  source = "git::https://github.com/ComputeCanada/magic_castle.git//gcp"

  cluster_name = "phoenix"
  domain       = "calculquebec.cloud"
  image        = "centos-7"
  nb_users     = 10

  instances = {
    mgmt  = { type = "n1-standard-2", count = 1 },
    login = { type = "n1-standard-2", count = 1 },
    node  = [
      { type = "n1-standard-2", count = 1 },
      # { type = "n1-standard-2", count = 1, prefix = "gpu", gpu_type = "nvidia-tesla-k80", gpu_count = 1 },
    ]
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

  # GCP specifics
  project = "calcul-quebec-249013"
  region  = "us-central1"
}

output "sudoer_username" {
  value = module.gcp.sudoer_username
}

output "guest_usernames" {
  value = module.gcp.guest_usernames
}

output "guest_passwd" {
  value = module.gcp.guest_passwd
}

output "public_ip" {
  value = module.gcp.ip
}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare"
#   name             = module.gcp.cluster_name
#   domain           = module.gcp.domain
#   email            = "you@example.com"
#   public_ip        = module.gcp.ip
#   rsa_public_key   = module.gcp.rsa_public_key
#   sudoer_username  = module.gcp.sudoer_username
# }

# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud"
#   email            = "you@example.com"
#   project          = "your-project-name"
#   zone_name        = "you-zone-name"
#   name             = module.gcp.cluster_name
#   domain           = module.gcp.domain
#   public_ip        = module.gcp.ip
#   rsa_public_key   = module.gcp.rsa_public_key
#   sudoer_username  = module.gcp.sudoer_username
# }

# output "hostnames" {
# 	value = module.dns.hostnames
# }
