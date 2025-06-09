terraform {
  required_version = ">= 1.5.7"
}

module "incus" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//incus"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "main"

  cluster_name = "phoenix"
  domain       = "calculquebec.cloud"
  image        = "rockylinux/9/cloud"

  instances = {
    mgmt   = { type = "container", cpus = 4, ram = 6000, tags = ["puppet", "mgmt", "nfs"], count = 1 }
    login  = { type = "container", cpus = 2, ram = 3000, tags = ["login", "public", "proxy"], count = 1 }
    node   = { type = "container", cpus = 2, ram = 3000, tags = ["node"], count = 1 }
  }

  volumes = {}

  public_keys = []
  hieradata = file("data.yaml")

  nb_users = 10
  # Shared password, randomly chosen if blank
  guest_passwd = ""
}
