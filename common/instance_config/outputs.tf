output "user_data" {
  value = local.user_data
}

output "rsa_hostkeys" {
  value = { for x, values in var.instances: x => tls_private_key.rsa_hostkeys[var.host2prefix[x]].public_key_openssh }
}

output "private_key" {
  value = try(tls_private_key.ssh[0].private_key_pem, null)
}