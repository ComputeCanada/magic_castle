variable "instances" { }
variable "config_git_url" { }
variable "config_version" { }
variable "puppetservers" { }
variable "puppetserver_password" { }
variable "sudoer_username" { }
variable "ssh_authorized_keys" { }
variable "hostkeys" { }
variable "terraform_data" { }
variable "terraform_facts" { }

locals {
  user_data = {
    for key, values in var.instances : key =>
    templatefile("${path.module}/puppet.yaml",
      {
        tags                  = values["tags"]
        node_name             = key,
        puppetenv_git         = var.config_git_url,
        puppetenv_rev         = var.config_version,
        puppetservers         = var.puppetservers,
        puppetserver_password = var.puppetserver_password,
        sudoer_username       = var.sudoer_username,
        ssh_authorized_keys   = var.ssh_authorized_keys
        terraform_data        = var.terraform_data
        terraform_facts       = var.terraform_facts
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
