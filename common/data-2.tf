resource "random_string" "munge_key" {
  length  = 32
  special = false
}

resource "random_string" "puppetmaster_password" {
  length  = 32
  special = false
}

resource "random_string" "freeipa_passwd" {
  length  = 16
  special = false
}

resource "random_pet" "guest_passwd" {
  count     = var.guest_passwd != "" ? 0 : 1
  length    = 4
  separator = "."
}

resource "random_uuid" "consul_token" {}

resource "tls_private_key" "ssh" {
  count     = var.generate_ssh_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "rsa_hostkeys" {
  for_each  = toset(keys(var.instances))
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  user_data = {
    for key, values in local.instances : key =>
    templatefile("${path.module}/cloud-init/puppet.yaml",
      {
        tags                  = values["tags"]
        node_name             = key,
        puppetenv_git         = var.config_git_url,
        puppetenv_rev         = var.config_version,
        puppetmaster_ip       = local.puppetmaster_ip,
        puppetmaster_password = random_string.puppetmaster_password.result,
        sudoer_username       = var.sudoer_username,
        ssh_authorized_keys   = var.public_keys,
        hostkeys = {
          rsa = {
            private = tls_private_key.rsa_hostkeys[local.host2prefix[key]].private_key_pem
            public  = tls_private_key.rsa_hostkeys[local.host2prefix[key]].public_key_openssh
          }
        }
      }
    )
  }
}
