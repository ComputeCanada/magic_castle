output "ip" {
  value = "${local.public_ip}"
}

output "domain_name" {
  value = "${var.domain_name}"
}

output "admin_passwd" {
  value = "${random_string.admin_passwd.result}"
}

output "guest_passwd" {
  value = "${random_pet.guest_passwd.id}"
}
