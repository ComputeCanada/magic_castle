terraform {
  required_version = ">= 1.5.7"
}

module "openstack" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//openstack"
  config_git_url = "https://github.com/MagicCastle/spark-environment.git"
  config_version = "main"

  cluster_name = "spark-test"
  domain       = "computecanada.dev"
  image        = "Rocky-9"

  instances = {
    puppet = { type = "p2-3.75gb", tags = ["puppet"] }
    master = { type = "p2-3.75gb", tags = ["master"], count = 1 }
    worker = { type = "p2-3.75gb", tags = ["worker", "data"], count = 3 }
    login  = { type = "p2-3.75gb", tags = ["public"], count = 1 }
  }

  volumes = {
    data = {
      data1 = { size = 50 }
    }
  }

  public_keys = [file("~/.ssh/id_rsa.pub")]
}

output "public_ip" {
  value = module.openstack.public_ip
}

output "sudoer" {
  value = module.openstack.accounts.sudoer
}
