terraform {
  required_version = ">= 1.4.0"
}

variable "pool" {
  description = "Slurm pool of compute nodes"
  default = []
}

module "gcp" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//gcp"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "main"

  cluster_name = "phoenix"
  domain       = "calculquebec.cloud"
  image        = "rocky-linux-9-optimized-gcp"

  instances = {
    mgmt   = { type = "n2-standard-2", tags = ["puppet", "mgmt", "nfs"], count = 1 }
    login  = { type = "n2-standard-2", tags = ["login", "public", "proxy"], count = 1 }
    node   = { type = "n2-standard-2", tags = ["node"], count = 1 }
    gpu    = {
      type = "n1-standard-2",
      tags = ["node"],
      count = 1,
      gpus = 1
      gpu_type = "nvidia-tesla-t4",
    }
  }

  # var.pool is managed by Slurm through Terraform REST API.
  # To let Slurm manage a type of nodes, add "pool" to its tag list.
  # When using Terraform CLI, this parameter is ignored.
  # Refer to Magic Castle Documentation - Enable Magic Castle Autoscaling
  pool = var.pool

  volumes = {
    nfs = {
      home     = { size = 10 }
      project  = { size = 50 }
      scratch  = { size = 50 }
    }
  }

  public_keys = [file("~/.ssh/id_rsa.pub")]

  nb_users     = 10
  # Shared password, randomly chosen if blank
  guest_passwd = ""

  # GCP specifics
  project = "your-project-12345"
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
