module "azure" {
  source = "git::ssh://gitlab@git.computecanada.ca/fafor10/slurm_cloud.git//azure"

  # JupyterHub + Slurm definition
  cluster_name        = "phoenix"
  nb_nodes            = 5
  nb_users            = 10
  shared_storage_size = 100
  domain_name         = "jupyter2.calculquebec.cloud"
  public_key_path = "./key.pub"

  # Azure specifics
  location            = "eastus"
  vm_size_mgmt        = "Standard_DS1_v2"
  vm_size_login       = "Standard_DS1_v2"
  vm_size_node        = "Standard_DS1_v2"
}

output "public_ip" {
	value = "${module.azure.ip}"
}

output "domain_name" {
	value = "${module.azure.domain_name}"
}

output "admin_passwd" {
	value = "${module.azure.admin_passwd}"
}

output "guest_passwd" {
	value = "${module.azure.guest_passwd}"
}
