resource "random_string" "puppetserver_password" {
  length  = 32
  special = false
}

resource "tls_private_key" "ssh" {
  count     = var.generate_ssh_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "rsa_hostkeys" {
  for_each  = toset([for x, values in var.instances: values["prefix"]])
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  user_data = {
    for key, values in var.instances : key =>
    templatefile("${path.module}/puppet.yaml",
      {
        tags                  = values["tags"]
        node_name             = key,
        puppetenv_git         = var.config_git_url,
        puppetenv_rev         = var.config_version,
        puppetserver_ip       = var.puppetserver_ip,
        puppetserver_password = random_string.puppetserver_password.result,
        sudoer_username       = var.sudoer_username,
        ssh_authorized_keys   = concat(var.public_keys, tls_private_key.ssh[*].public_key_openssh),
        hostkeys = {
          rsa = {
            private = tls_private_key.rsa_hostkeys[values["prefix"]].private_key_pem
            public  = tls_private_key.rsa_hostkeys[values["prefix"]].public_key_openssh
          }
        }
      }
    )
  }
}
