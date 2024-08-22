variable "inventory" { }
variable "config_git_url" { }
variable "config_version" { }

variable "sudoer_username" { }

variable "nb_users" { }
variable "software_stack" { }
variable "cloud_provider" { }
variable "cloud_region" { }
variable "domain_name" { }
variable "cluster_name" { }
variable "guest_passwd" { }

variable "public_keys" { }

variable "skip_upgrade" { }
variable "puppetfile" { }
variable "bastion_tag" { }

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "tls_private_key" "rsa" {
  for_each  = toset([for x, values in var.inventory: values.prefix])
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "ed25519" {
  for_each  = toset([for x, values in var.inventory: values.prefix])
  algorithm = "ED25519"
}

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

  puppetservers = { for host, values in var.inventory: host => values.local_ip if contains(values.tags, "puppet")}
  all_tags = toset(flatten([for key, values in var.inventory : values.tags]))
  tag_ip = { for tag in local.all_tags :
    tag => [for key, values in var.inventory : values.local_ip if contains(values.tags, tag)]
  }

  # add openssh public key to inventory
  inventory = { for host, values in var.inventory:
    host => merge(values, {
      hostkeys = {
        rsa     = chomp(tls_private_key.rsa[values.prefix].public_key_openssh)
        ed25519 = chomp(tls_private_key.ed25519[values.prefix].public_key_openssh)
      }
    })
  }

  terraform_data  = yamlencode({
    terraform = {
      instances = local.inventory
      tag_ip    = local.tag_ip
      data      = {
        sudoer_username = var.sudoer_username
        public_keys     = var.public_keys
        cluster_name    = lower(var.cluster_name)
        domain_name     = var.domain_name
        guest_passwd    = local.guest_passwd
        nb_users        = var.nb_users
      }
    }
  })

  terraform_facts = yamlencode({
    software_stack = var.software_stack,
  })

  user_data = {
    for key, values in var.inventory : key =>
    templatefile("${path.module}/puppet.yaml",
      {
        cloud_provider        = var.cloud_provider
        cloud_region          = var.cloud_region
        tags                  = values.tags
        node_name             = key,
        node_prefix           = values.prefix,
        domain_name           = var.domain_name
        puppetenv_git         = var.config_git_url,
        puppetenv_rev         = var.config_version,
        puppetservers         = local.puppetservers,
        puppetserver_password = local.puppet_passwd,
        sudoer_username       = var.sudoer_username,
        ssh_authorized_keys   = var.public_keys
        tf_ssh_public_key     = tls_private_key.ssh.public_key_openssh
        # If there is no bastion, the terraform data has to be packed with the user_data of the puppetserver.
        # We do not packed it systematically because it increases the user-data size to a value that can be
        # near or exceeds the cloud provider limit - AWS 16KB, Azure and OpenStack 64KB, GCP 256 KB.
        include_tf_data       = ! contains(local.all_tags, var.bastion_tag)
        terraform_data        = local.terraform_data
        terraform_facts       = local.terraform_facts
        skip_upgrade          = var.skip_upgrade
        puppetfile            = var.puppetfile
        hostkeys = {
          rsa = {
            private = chomp(tls_private_key.rsa[values.prefix].private_key_openssh)
            public  = chomp(tls_private_key.rsa[values.prefix].public_key_openssh)
          }
          ed25519 = {
            private = chomp(tls_private_key.ed25519[values.prefix].private_key_openssh)
            public  = chomp(tls_private_key.ed25519[values.prefix].public_key_openssh)
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

output "inventory" {
  value = local.inventory
}

output "ssh_key" {
  value = {
    public  = try("${chomp(tls_private_key.ssh.public_key_openssh)} tf@localhost", null)
    private = try(tls_private_key.ssh.private_key_pem, null)
  }
}

output "bastions" {
  value = {
    for host, values in var.inventory: host => values
    if contains(values.tags, var.bastion_tag) && contains(values.tags, "public") &&  (!contains(values.tags, "pool"))
  }
}
