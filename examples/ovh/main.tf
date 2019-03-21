module "ovh" {
  source = "git::ssh://gitlab@git.computecanada.ca/magic_castle/slurm_cloud.git//ovh"

  # Cluster customization
  puppet_config       = "jupyterhub"
  cluster_name        = "phoenix"
  domain              = "calculquebec.cloud"
  nb_nodes            = 5
  nb_users            = 10
  home_size           = 100
  project_size        = 50
  scratch_size        = 50
  public_key_path     = "./key.pub"

  # OpenStack specifics
  os_external_network = "Ext-Net"
  os_image_id         = "bd049ab8-860e-499d-b1e2-7c4e31c469e5"
  os_flavor_node      = "s1-2"
  os_flavor_login     = "s1-2"
  os_flavor_mgmt      = "s1-2"
}

output "admin_username" {
  value = "${module.ovh.admin_username}"
}
output "freeipa_admin_passwd" {
  value = "${module.ovh.freeipa_admin_passwd}"
}

output "guest_usernames" {
  value = "${module.ovh.guest_usernames}"
}

output "guest_passwd" {
  value = "${module.ovh.guest_passwd}"
}

output "public_ip" {
  value = "${module.ovh.ip}"
}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::ssh://gitlab@git.computecanada.ca/magic_castle/slurm_cloud.git//dns/cloudflare"
#   name             = "${module.ovh.cluster_name}"
#   domain           = "${module.ovh.domain}"
#   public_ip        = "${module.ovh.ip}"
#   rsa_public_key   = "${module.ovh.rsa_public_key}"
#   ecdsa_public_key = "${module.ovh.ecdsa_public_key}"
# }
# output "domain_name" {
# 	value = "${module.dns.domain_name}"
# }
