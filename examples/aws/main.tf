module "aws" {
  source = "git::ssh://gitlab@git.computecanada.ca/fafor10/slurm_cloud.git//aws"

  # JupyterHub + Slurm definition
  cluster_name        = "phoenix"
  nb_nodes            = 5
  nb_users            = 10
  shared_storage_size = 100
  domain_name         = "jupyter2.calculquebec.cloud"
  public_key_path     = "./key.pub"

  # AWS specifics
  region = "ca-central-1"
  instance_type_node = "t2.micro"
  instance_type_mgmt = "t2.micro"
  instance_type_login = "t2.micro"
}

output "public_ip" {
	value = "${module.aws.ip}"
}

output "domain_name" {
	value = "${module.aws.domain_name}"
}

output "admin_passwd" {
	value = "${module.aws.admin_passwd}"
}

output "guest_passwd" {
	value = "${module.aws.guest_passwd}"
}
