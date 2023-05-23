variable "instances" { }
variable "nb_users" { }
variable "software_stack" { }
variable "cloud_provider" { }
variable "cloud_region" { }
variable "sudoer_username" { }
variable "ssh_authorized_keys" { }
variable "guest_passwd" { }
variable "domain_name" { }
variable "cluster_name" { }
variable "volume_devices" { }

locals {
  all_tags = toset(flatten([for key, values in var.instances : values["tags"]]))

  tag_ip = { for tag in local.all_tags :
    tag => [for key, values in var.instances : values["local_ip"] if contains(values["tags"], tag)]
  }
}

output "result" {
  value = {
    data  = yamlencode({
      terraform = {
        instances = var.instances
        tag_ip    = local.tag_ip
        volumes   = var.volume_devices
        data      = {
          sudoer_username = var.sudoer_username
          public_keys     = var.ssh_authorized_keys
          cluster_name    = lower(var.cluster_name)
          domain_name     = var.domain_name
          guest_passwd    = var.guest_passwd
          nb_users        = var.nb_users
        }
      }
    })
    facts = yamlencode({
      software_stack = var.software_stack
      cloud          = {
        provider = var.cloud_provider
        region = var.cloud_region
      }
    })
  }
}
