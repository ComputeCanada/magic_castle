variable "generate_ssh_key" { }
variable "public_keys" { }
variable "instances" { }

resource "tls_private_key" "ssh" {
  count     = var.generate_ssh_key ? 1 : 0
  algorithm = "ED25519"
}

resource "tls_private_key" "rsa" {
  for_each  = toset([for x, values in var.instances: values["prefix"]])
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "ed25519" {
  for_each  = toset([for x, values in var.instances: values["prefix"]])
  algorithm = "ED25519"
}

output "hostkeys" {
  value = { 
    rsa = { for x, values in var.instances : x => tls_private_key.rsa[values["prefix"]] } 
    ed25519 = { for x, values in var.instances : x => tls_private_key.ed25519[values["prefix"]] }
  }
} 

locals { 
  ssh_key  = {
    public  = try("${chomp(tls_private_key.ssh[0].public_key_openssh)} terraform@localhost", null)
    private = try(tls_private_key.ssh[0].private_key_pem, null)
  }
} 

output "ssh_key" {
  value = local.ssh_key
}

output "ssh_authorized_keys" {
  value = var.generate_ssh_key ? concat(var.public_keys, [local.ssh_key.public]) :  var.public_keys
}