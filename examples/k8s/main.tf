terraform {
  required_version = ">= 1.5.7"
}

module "k8s" {
  source         = "../../k8s"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "main"

  cluster_name = "phoenix"
  domain       = "calculquebec.cloud"
  image        = "Rocky-9"

  instances = {
    mgmt   = { type = "container", cpus = 4, ram = 6000, tags = ["puppet", "mgmt", "nfs"], count = 1 }
    login  = { type = "container", cpus = 2, ram = 3000, tags = ["login", "proxy"], count = 1 }
    node   = { type = "container", cpus = 2, ram = 3000, tags = ["node"], count = 1 }
  }

  volumes = {
    nfs = {
      home     = { size = 100 }
      project  = { size = 50 }
      scratch  = { size = 50 }
    }
  }

  public_keys = [file("~/.ssh/id_rsa.pub")]

  nb_users = 10
  # Shared password, randomly chosen if blank
  guest_passwd = ""
}
