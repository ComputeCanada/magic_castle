module "openstack" {
  source = "git::ssh://gitlab@git.computecanada.ca/magic_castle/slurm_cloud.git//openstack"

  # Cluster customization
  puppet_config       = "jupyterhub"
  cluster_name        = "phoenix"
  domain              = "calculquebec.cloud"
  nb_nodes            = 5
  nb_users            = 10
  home_size           = 100
  project_size        = 50
  scratch_size        = 50
  public_key_path     = "./pub.key"
  # Shared password, randomly chosen if blank
  guest_passwd = ""

  # OpenStack specifics
  os_image_name        = "CentOS-7-x64-2018-09"
  os_flavor_node       = "p2-3gb"
  os_flavor_login      = "p2-3gb"
  os_flavor_mgmt       = "p4-6gb"
  os_floating_ips      = []
}

output "admin_username" {
  value = "${module.openstack.admin_username}"
}
output "freeipa_admin_passwd" {
  value = "${module.openstack.freeipa_admin_passwd}"
}

output "guest_usernames" {
  value = "${module.openstack.guest_usernames}"
}

output "guest_passwd" {
  value = "${module.openstack.guest_passwd}"
}

output "public_ip" {
  value = "${module.openstack.ip}"
}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::ssh://gitlab@git.computecanada.ca/magic_castle/slurm_cloud.git//dns/cloudflare"
#   name             = "${module.openstack.cluster_name}"
#   domain           = "${module.openstack.domain}"
#   public_ip        = "${module.openstack.ip}"
#   rsa_public_key   = "${module.openstack.rsa_public_key}"
#   nb_login         = "${module.openstack.nb_login}"
# }
# output "hostnames" {
# 	value = "${module.dns.hostnames}"
# }
