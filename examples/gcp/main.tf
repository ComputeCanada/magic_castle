terraform {
  required_version = ">= 0.12"
}

module "gcp" {
  source = "git::ssh://gitlab@git.computecanada.ca/magic_castle/slurm_cloud.git//gcp"

  # Cluster customization
  cluster_name    = "phoenix"
  domain          = "calculquebec.cloud"
  sudoer_username = "castle"
  nb_nodes        = 5
  nb_users        = 10

  storage = {
    type         = "nfs"
    home_size    = 100
    project_size = 50
    scratch_size = 50
  }

  public_key_path = "~/.ssh/id_rsa.pub"

  # GCP specifics
  project_name = "crested-return-137823"
  region       = "us-central1"
  zone         = "us-central1-a"
  gcp_image    = "centos-7"

  machine_type_mgmt  = "n1-standard-2"
  machine_type_login = "n1-standard-2"
  machine_type_node  = "n1-standard-2"

  # ["GPU card", count]
  gpu_per_node = ["nvidia-tesla-k80", 0]
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
#   source           = "git::ssh://gitlab@git.computecanada.ca/magic_castle/slurm_cloud.git//dns/cloudflare"
#   name             = module.gcp.cluster_name
#   domain           = module.gcp.domain
#   public_ip        = module.gcp.ip
#   rsa_public_key   = module.gcp.rsa_public_key
#   sudoer_username  = module.gcp.sudoer_username
# }
# output "hostnames" {
# 	value = module.dns.hostnames
# }
