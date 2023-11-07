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

variable "cacao_user_data" {
  type = string
  description = "cloud init script; not currently used"
  default = ""
}

# variable "cacao_public_key" {
#   type = string
#   description = "if set, will be an additional key used"
#   default = ""
# }

variable "cacao_whitelist_ips" {
  type = string
  description = "comma-separated list of ips to whitelist to fail2ban"
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

  public_keys = local.cacao_user_data_yaml.users[1].ssh_authorized_keys

  # generate_ssh_key = true

  nb_users = var.guest_users_count
  # Shared password, randomly chosen if blank
  guest_passwd = var.guest_users_password

  sudoer_username = local.system_user

  hieradata = length(local.cacao_whitelist_ips) == 0 ? "" : <<-EOT
fail2ban::ignoreip:
%{ for ip in local.cacao_whitelist_ips }
  - ${ip}
%{ endfor }
EOT
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

locals {
  # identify the system user
  split_username = split("@", var.username)
  system_user = local.split_username[0]
  cacao_user_data_yaml = try(yamldecode(var.cacao_user_data), "")
  cacao_whitelist_ips = split(",", var.cacao_whitelist_ips)
}

resource "null_resource" "cacao_helper_scripts" {
  depends_on = [
    module.openstack.public_ip
  ]
  connection {
    type        = "ssh"
    user        = local.system_user
    host        = module.openstack.public_ip.login1
  }
  provisioner "file" {
    content = <<-EOT
#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)
magenta_bold="\e[1;35m"
yellow_bold="\e[1;33m"

# redirecting stdout to stderr to prevent file transfer problems
echo -e "\nWelcome to the Magic Castle login node!\n" 1>&2
CURRENT_STATE="$(mccheck)"
echo -e "Magic Castle's current state is $CURRENT_STATE" 1>&2
if [ "$CURRENT_STATE" == *"NOT READY"* ]; then
    echo -e "You may want to grab some coffee while you wait." 1>&2
    echo -e "Most recent puppet activity: $(journalctl -u puppet|tail -1)\n" 1>&2
else
    echo -e "" 1>&2
fi
echo -e "To re-check Magic Castle state: $${magenta_bold}mccheck$${normal}" 1>&2
echo -e "Account info for this cluster: $${magenta_bold}/edwin/accounts.txt$${normal}\n" 1>&2
EOT
    destination = "/${local.system_user}/.ssh/rc"
  }

  provisioner "file" {
    content = <<-EOT
#!/bin/bash
yellow_bold="\e[1;33m"
green_bold="\e[1;32m"
normal=$(tput sgr0)
# check if magic castle has the following line
# this simple test for now; until a better check is available, let's simply check for the final line
# I'm sure a more robust check can be provided by more experienced MC folks :)
journalctl -u puppet|grep -q 'Applied catalog in'
if [ $? -ne 0 ]; then
        echo "$${yellow_bold}NOT READY$${normal}"
else
        echo "$${green_bold}READY$${normal}"
fi
EOT
    destination = "/tmp/mccheck"
  }

  provisioner "file" {
    content = <<-EOT

The following is the account information:

usernames: ${module.openstack.accounts.guests.usernames}
password: ${module.openstack.accounts.guests.password}

EOT
    destination = "/${local.system_user}/accounts.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/mccheck /${local.system_user}/.ssh/rc",
      "sudo mv /tmp/mccheck /usr/local/bin/",
    ]
  }
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
