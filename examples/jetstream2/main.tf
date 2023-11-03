terraform {
  required_version = ">= 1.4.0"
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack" # "terraform.cyverse.org/cyverse/openstack"
    }
  }

}

provider "openstack" {
  tenant_name = var.project
  region = var.region
}

variable "username" {
  type = string
  description = "username"
}

variable "region" {
  type = string
  description = "string, openstack region name; default = IU"
  default = "IU"
}

variable "project" {
  type = string
  description = "project name"
}

variable "domain_name" {
  description = "Name of the cluster"
  default = "jetstream-cloud.org"
}

variable "instance_name" {
  description = "Name of the cluster"
  default = "phoenix"
}

variable "pool" {
  description = "Slurm pool of compute nodes"
  default = []
}

variable "image_name" {
  type = string
  description = "string, name of image; image will have priority if both image and image name are provided"
  default = "Featured-RockyLinux8"
}

variable "mgmt_flavor" {
  type = string
  description = "mgmt flavor or size of instance to launch"
  default = "m3.medium"
}

variable "login_flavor" {
  type = string
  description = "login flavor or size of instance to launch"
  default = "m3.medium"
}

variable "node_flavor" {
  type = string
  description = "node flavor or size of instance to launch"
  default = "m3.medium"
}

variable "login_count" {
  type = number
  description = "number of login instances to launch"
  default = 1
}

variable "mgmt_count" {
  type = number
  description = "number of mgmt instances to launch"
  default = 1
}

variable "node_count" {
  type = number
  description = "number of node instances to launch"
  default = 1
}

variable "guest_users_count" {
  type = number
  description = "number of guest users"
  default = 10
}

variable "guest_users_password" {
  type = string
  description = "password to use for guest users"
  default = ""
}

variable "keypair" {
  type = string
  description = "keypair to use when launching"
  default = ""
}

variable "power_state" {
  type = string
  description = "power state of instance; current has no effect"
  default = "active"
}

variable "user_data" {
  type = string
  description = "cloud init script; not currently used"
  default = ""
}

module "openstack" {
  source         = "./openstack"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "main"

  cluster_name = var.instance_name
  domain       = "${var.project}.${var.domain_name}"
  image        = var.image_name

  instances = {
    mgmt   = { type = var.mgmt_flavor, tags = ["puppet", "mgmt", "nfs"], count = var.mgmt_count }
    login  = { type = var.login_flavor, tags = ["login", "public", "proxy"], count = var.login_count }
    node   = { type = var.node_flavor, tags = ["node"], count = var.node_count }
  }

  # var.pool is managed by Slurm through Terraform REST API.
  # To let Slurm manage a type of nodes, add "pool" to its tag list.
  # When using Terraform CLI, this parameter is ignored.
  # Refer to Magic Castle Documentation - Enable Magic Castle Autoscaling
  pool = var.pool

  volumes = {
    nfs = {
      home     = { size = 100 }
      project  = { size = 50 }
      scratch  = { size = 50 }
    }
  }

  # does not work

  public_keys = [data.openstack_compute_keypair_v2.kp[0].public_key]

  generate_ssh_key = true

  nb_users = var.guest_users_count
  # Shared password, randomly chosen if blank
  guest_passwd = var.guest_users_password

  sudoer_username = var.username
}

resource "null_resource" "ssh-agent" {

    triggers = {
        always_run = "${timestamp()}"
    }

    provisioner "local-exec" {
        command = "`eval ssh-agent`; ssh-add"
    }

}


data "openstack_compute_keypair_v2" "kp" {
  count = var.keypair == "" ? 0 : 1
  name = var.keypair
}



output "accounts" {
  value = module.openstack.accounts
}

output "public_ip" {
  value = module.openstack.public_ip
}

module "dns" {
    source           = "./dns/txt"
    name             = module.openstack.cluster_name
    domain           = module.openstack.domain
    public_instances = module.openstack.public_instances
}

## Uncomment to register your domain name with CloudFlare
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare"
#   name             = module.openstack.cluster_name
#   domain           = module.openstack.domain
#   bastions         = module.openstack.bastions
#   public_instances = module.openstack.public_instances
#   ssh_private_key  = module.openstack.ssh_private_key
#   sudoer_username  = module.openstack.accounts.sudoer.username
# }

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/gcloud"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.openstack.cluster_name
#   domain           = module.openstack.domain
#   bastions         = module.openstack.bastions
#   public_instances = module.openstack.public_instances
#   ssh_private_key  = module.openstack.ssh_private_key
#   sudoer_username  = module.openstack.accounts.sudoer.username
# }

# output "hostnames" {
#   value = module.dns.hostnames
# }
