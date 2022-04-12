resource "random_string" "puppetserver_password" {
  length  = 32
  special = false
}

resource "tls_private_key" "ssh" {
  count     = var.generate_ssh_key ? 1 : 0
  algorithm = "ED25519"
}

resource "tls_private_key" "rsa_hostkeys" {
  for_each  = toset([for x, values in var.instances: values["prefix"]])
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "ed25519_hostkeys" {
  for_each  = toset([for x, values in var.instances: values["prefix"]])
  algorithm = "ED25519"
}

locals {
  ssh_key = {
    public  = try("${chomp(tls_private_key.ssh[0].public_key_openssh)} terraform@localhost", null)
    private = try(tls_private_key.ssh[0].private_key_pem, null)
  }
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
        ssh_authorized_keys   = local.ssh_key.public == null ? var.public_keys : concat(var.public_keys, [local.ssh_key.public])
        hostkeys = {
          rsa = {
            private = tls_private_key.rsa_hostkeys[values["prefix"]].private_key_pem
            public  = tls_private_key.rsa_hostkeys[values["prefix"]].public_key_openssh
          }
          ed25519 = {
            private = tls_private_key.ed25519_hostkeys[values["prefix"]].private_key_openssh
            public  = tls_private_key.ed25519_hostkeys[values["prefix"]].public_key_openssh
          }
        }
      }
    )
  }
}
