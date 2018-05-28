module "azure" {
  source = "git::ssh://gitlab@git.computecanada.ca/fafor10/slurm_cloud.git//azure"

  # JupyterHub + Slurm definition
  cluster_name        = "phoenix"
  nb_nodes            = 5
  nb_users            = 10
  shared_storage_size = 100
  domain_name         = "jupyter2.calculquebec.cloud"

  # Azure specifics
  path_ssh_public_key = "./key.pub"
  location            = "eastus"
  vm_size_mgmt        = "Standard_DS1_v2"
  vm_size_login       = "Standard_DS1_v2"
  vm_size_node        = "Standard_DS1_v2"
}
