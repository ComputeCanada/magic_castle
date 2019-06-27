terraform {
  required_version = ">= 0.12"
}

module "aws" {
  source = "git::ssh://gitlab@git.computecanada.ca/magic_castle/slurm_cloud.git//aws"

  # Cluster customization
  puppet_config   = "jupyterhub"
  cluster_name    = "phoenix"
  domain          = "calculquebec.cloud"
  nb_nodes        = 5
  nb_users        = 10
  home_size       = 100
  project_size    = 50
  scratch_size    = 50
  public_key_path = "./key.pub"

  # AWS specifics
  region              = "ca-central-1"
  availability_zone   = "ca-central-1a"
  instance_type_node  = "t2.micro"
  instance_type_mgmt  = "t2.micro"
  instance_type_login = "t2.micro"
}

output "public_ip" {
  value = module.aws.ip
}

output "domain_name" {
  value = module.aws.domain_name
}

output "guest_passwd" {
  value = module.aws.guest_passwd
}
