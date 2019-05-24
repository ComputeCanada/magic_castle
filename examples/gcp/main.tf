module "gcp" {
  source = "git::ssh://gitlab@git.computecanada.ca/magic_castle/slurm_cloud.git//gcp"

  # Cluster customization
  puppet_config       = "jupyterhub"
  cluster_name        = "phoenix"
  domain_name         = "calculquebec.cloud"
  nb_nodes            = 5
  nb_users            = 10
  home_size           = 100
  project_size        = 50
  scratch_size        = 50
  public_key_path     = "./key.pub"

  # GCP specifics
  project_name       = "crested-return-137823"
  zone               = "us-central1"
  zone_region        = "us-central1-a"
  gcp_image          = "centos-7"
  # Minimun size to install freeipa-server
  machine_type_mgmt  = "g1-small"
  machine_type_login = "g1-small"
  machine_type_node  = "n1-standard-1"
  # ["GPU card", count]
  gpu_per_node       = ["nvidia-tesla-k80", 1]

}

output "admin_username" {
  value = "${module.gcp.admin_username}"
}
output "freeipa_admin_passwd" {
  value = "${module.gcp.freeipa_admin_passwd}"
}

output "guest_usernames" {
  value = "${module.gcp.guest_usernames}"
}

output "guest_passwd" {
  value = "${module.gcp.guest_passwd}"
}

output "public_ip" {
  value = "${module.gcp.ip}"
}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::ssh://gitlab@git.computecanada.ca/magic_castle/slurm_cloud.git//dns/cloudflare"
#   name             = "${module.gcp.cluster_name}"
#   domain           = "${module.gcp.domain}"
#   public_ip        = "${module.gcp.ip}"
#   rsa_public_key   = "${module.gcp.rsa_public_key}"
#   nb_login         = "${module.openstack.nb_login}"
# }
# output "domain_name" {
# 	value = "${module.dns.domain_name}"
# }
