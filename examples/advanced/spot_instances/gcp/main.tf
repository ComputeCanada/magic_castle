terraform {
  required_version = ">= 1.5.7"
}

module "gcp" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//gcp"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "main"

  cluster_name = "spot-gcp"
  domain       = "calculquebec.cloud"
  image        = "rocky-linux-9"
  nb_users     = 10

  instances = {
    mgmt   = { type = "n1-standard-2", tags = ["puppet", "mgmt", "nfs"], count = 1 }
    login  = { type = "n1-standard-2", tags = ["login", "public", "proxy"], count = 1 }
    node   = {
        tags  = ["node", "spot"],
        type  = "n1-standard-2",
        count = 1
    }
  }

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
  project = "my-company-12345"
  region  = "us-central1"
}

output "accounts" {
  value = module.gcp.accounts
}

output "public_ip" {
  value = module.gcp.public_ip
}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare"
#   name             = module.gcp.cluster_name
#   domain           = module.gcp.domain
#   public_instances = module.gcp.public_instances
# }

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.gcp.cluster_name
#   domain           = module.gcp.domain
#   public_instances = module.gcp.public_instances
# }

# output "hostnames" {
# 	value = module.dns.hostnames
# }
