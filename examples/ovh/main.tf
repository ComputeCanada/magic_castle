module "ovh" {
  source = "git::ssh://gitlab@git.computecanada.ca/fafor10/slurm_cloud.git//ovh"

  # JupyterHub + Slurm definition
  cluster_name        = "phoenix"
  nb_nodes            = 5
  nb_users            = 10
  shared_storage_size = 100
  domain_name         = "jupyter2.calculquebec.cloud"
  public_key_path     = "./key.pub"

  # OpenStack specifics
  os_external_network = "Ext-Net"
  os_image_id         = "bd049ab8-860e-499d-b1e2-7c4e31c469e5"
  os_flavor_node      = "s1-2"
  os_flavor_login     = "s1-2"
  os_flavor_mgmt      = "s1-2"
}

output "public_ip" {
	value = "${module.ovh.ip}"
}

output "domain_name" {
	value = "${module.ovh.domain_name}"
}

output "admin_passwd" {
	value = "${module.ovh.admin_passwd}"
}

output "guest_passwd" {
	value = "${module.ovh.guest_passwd}"
}
