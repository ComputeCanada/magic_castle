terraform {
  required_version = ">= 1.5.7"
}

module "openstack" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//openstack"
  config_git_url = "https://github.com/MagicCastle/elk-environment.git"
  config_version = "main"

  cluster_name = "odfe-cluster"
  domain       = "computecanada.dev"
  image        = "Rocky-9"

  instances = {
    puppet = { type = "p2-3.75gb", tags = ["puppet"] }
    master = { type = "p2-3.75gb", tags = ["master"], count = 1 }
    ingest = { type = "p2-3.75gb", tags = ["ingest", "public"], count = 1 }
    data   = { type = "p2-3.75gb", tags = ["data"], count = 2 }
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
