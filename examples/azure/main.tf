terraform {
  required_version = ">= 0.12"
}

module "azure" {
  source = "git::ssh://gitlab@git.computecanada.ca/magic_castle/slurm_cloud.git//azure"

  # Cluster customization
  puppet_config   = "jupyterhub"
  cluster_name    = "phoenix"
  domain          = "calculquebec.cloud"
  nb_nodes        = 5
  nb_users        = 10

  storage = {
    type         = "nfs"
    home_size    = 100
    project_size = 50
    scratch_size = 50
  }

  public_key_path = "./key.pub"

  # Azure specifics
  location      = "eastus"
  vm_size_mgmt  = "Standard_DS1_v2"
  vm_size_login = "Standard_DS1_v2"
  vm_size_node  = "Standard_DS1_v2"
}

output "public_ip" {
  value = module.azure.ip
}

output "guest_passwd" {
  value = module.azure.guest_passwd
}
