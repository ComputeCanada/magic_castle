variable "inventory" { }
variable "config_git_url" { }
variable "config_version" { }

variable "sudoer_username" { }
variable "ssh_authorized_keys" { }
variable "hostkeys" { }

variable "nb_users" { }
variable "software_stack" { }
variable "cloud_provider" { }
variable "cloud_region" { }
variable "domain_name" { }
variable "cluster_name" { }
variable "volume_devices" { }
variable "guest_passwd" { }

resource "random_string" "puppet_passwd" {
  length  = 32
  special = false
}

resource "random_pet" "guest_passwd" {
  count     = var.guest_passwd != "" ? 0 : 1
  length    = 4
  separator = "."
}

locals {
  puppet_passwd = random_string.puppet_passwd.result
  guest_passwd = var.guest_passwd != "" ? var.guest_passwd : try(random_pet.guest_passwd[0].id, "")
}



locals {
  puppetservers    = { for host in keys(var.inventory): host => var.inventory[host].local_ip if contains(var.inventory[host].tags, "puppet")}
  all_tags = toset(flatten([for key, values in var.inventory : values["tags"]]))
  tag_ip = { for tag in local.all_tags :
    tag => [for key, values in var.inventory : values["local_ip"] if contains(values["tags"], tag)]
  }

  terraform_data  = yamlencode({
    terraform = {
      instances = var.inventory
      tag_ip    = local.tag_ip
      volumes   = var.volume_devices
      data      = {
        sudoer_username = var.sudoer_username
        public_keys     = var.ssh_authorized_keys
        cluster_name    = lower(var.cluster_name)
        domain_name     = var.domain_name
        guest_passwd    = local.guest_passwd
        nb_users        = var.nb_users
      }
    }
  })

  terraform_facts = yamlencode({
    software_stack = var.software_stack
    cloud          = {
      provider = var.cloud_provider
      region = var.cloud_region
    }
  })

  user_data = {
    for key, values in var.inventory : key =>
    templatefile("${path.module}/puppet.yaml",
      {
        tags                  = values["tags"]
        node_name             = key,
        puppetenv_git         = var.config_git_url,
        puppetenv_rev         = var.config_version,
        puppetservers         = local.puppetservers,
        puppetserver_password = local.puppet_passwd,
        sudoer_username       = var.sudoer_username,
        ssh_authorized_keys   = var.ssh_authorized_keys
        terraform_data        = local.terraform_data
        terraform_facts       = local.terraform_facts
        hostkeys = {
          rsa = {
            private = var.hostkeys["rsa"][key].private_key_pem
            public  = var.hostkeys["rsa"][key].public_key_openssh
          }
          ed25519 = {
            private = var.hostkeys["ed25519"][key].private_key_openssh
            public  = var.hostkeys["ed25519"][key].public_key_openssh
          }
        }
      }
    )
  }
}

output "user_data" {
  value     = local.user_data
  sensitive = true
}

output "terraform_data" {
  value = local.terraform_data
}

output "terraform_facts" {
  value = local.terraform_facts
}

output "puppetservers" {
  value = local.puppetservers
}

output "guest_passwd" {
  value = local.guest_passwd
}
