output "ip" {
  value = "${local.public_ip}"
}

output "cluster_name" {
  value = "${var.cluster_name}"
}
output "domain" {
  value = "${var.domain}"
}

output "admin_username" {
  value = "centos"
}

output "freeipa_admin_passwd" {
  value = "${random_string.admin_passwd.result}"
}

output "guest_usernames" {
  value = "user[${format(format("%%0%dd", ceil(log(var.nb_users,10))+1), 1)}-${var.nb_users}]"
}

output "guest_passwd" {
  value = "${random_pet.guest_passwd.id}"
}

output "rsa_public_key" {
  value = "${tls_private_key.login_rsa.public_key_openssh}"
}

output "ecdsa_public_key" {
  value = "${tls_private_key.login_ecdsa.public_key_openssh}"
}