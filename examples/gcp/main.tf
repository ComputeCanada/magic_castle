module "gcp" {
  source = "git::ssh://gitlab@git.computecanada.ca/fafor10/slurm_cloud.git//gcp"

  # JupyterHub + Slurm definition
  cluster_name        = "phoenix"
  nb_nodes            = 5
  nb_users            = 10
  shared_storage_size = 100
  domain_name         = "jupyter2.calculquebec.cloud"
  public_key_path     = "./key.pub"

  # GCP specifics
  project_name       = "crested-return-137823"
  credentials_file   = "./credentials.json"
  zone               = "us-central1"
  zone_region        = "us-central1-a"
  # Minimun size to install freeipa-server
  machine_type_mgmt  = "g1-small"
  machine_type_login = "g1-small"
  machine_type_node  = "n1-standard-1"
  # ["GPU card", count]
  gpu_per_node       = ["nvidia-tesla-k80", 1]

}
