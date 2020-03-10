output "ip" {
  value = local.public_ip
}

output "cluster_name" {
  value = var.cluster_name
}

output "domain" {
  value = "${lower(var.domain)}"
}

output "sudo_users" {
  value = var.sudo_users
}

output "freeipa_passwd" {
  value = random_string.freeipa_passwd.result
}

output "guest_usernames" {
  value = "user[${format(format("%%0%dd", length(tostring(var.nb_users))), 1)}-${var.nb_users}]"
}

output "guest_passwd" {
  value = var.guest_passwd != "" ? var.guest_passwd : random_pet.guest_passwd[0].id
}

output "rsa_public_key" {
  value = tls_private_key.login_rsa.public_key_openssh
}