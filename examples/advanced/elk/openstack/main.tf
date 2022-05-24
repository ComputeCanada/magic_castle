terraform {
  required_version = ">= 1.1.0"
}

module "openstack" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//openstack"
  config_git_url = "https://github.com/MagicCastle/elk-environment.git"
  config_version = "11.9.x"

  cluster_name = "odfe-cluster"
  domain       = "computecanada.dev"
  image        = "Rocky-8.5-x64-2021-11"

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

  # Magic Castle default firewall rules are too permissive
  # for this example. The following restricts it to SSH only.
  firewall_rules = [
    {"name"="SSH", "from_port"=22, "to_port"=22, "ip_protocol"="tcp", "cidr"="0.0.0.0/0"},
  ]
}

output "public_ip" {
  value = module.openstack.public_ip
}

output "sudoer" {
  value = module.openstack.accounts.sudoer
}
