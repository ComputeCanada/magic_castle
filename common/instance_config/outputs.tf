output "user_data" {
  value     = local.user_data
  sensitive = true
}

output "rsa_hostkeys" {
  value = { for x, values in var.instances : x => tls_private_key.rsa_hostkeys[values["prefix"]].public_key_openssh }
}

output "ed25519_hostkeys" {
  value = { for x, values in var.instances : x => tls_private_key.ed25519_hostkeys[values["prefix"]].public_key_openssh }
}


output "ssh_key" {
  value = local.ssh_key
}