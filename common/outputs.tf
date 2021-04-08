output "ip" {
  value = local.public_ip
}

output "cluster_name" {
  value = lower(var.cluster_name)
}

output "domain" {
  value = lower(var.domain)
}

output "sudoer_username" {
  value = var.sudoer_username
}

output "freeipa_passwd" {
  value = random_string.freeipa_passwd.result
}

output "guest_usernames" {
  value = var.nb_users != 0 ? (
    "user[${format(format("%%0%dd", length(tostring(var.nb_users))), 1)}-${var.nb_users}]"
  ) : (
    "You have chosen to create user accounts yourself (`nb_users = 0`), please read the documentation on how to manage this at https://github.com/ComputeCanada/magic_castle/blob/main/docs/README.md#103-add-a-user-account"
  )

}

output "guest_passwd" {
  value = var.guest_passwd != "" ? var.guest_passwd : try(random_pet.guest_passwd[0].id, "")
}

output "rsa_public_key" {
  value = tls_private_key.login_rsa.public_key_openssh
}

output "ssh_private_key" {
  value     = try(tls_private_key.ssh[0].private_key_pem, null)
  sensitive = true
}

output "login_ids" {
  value = local.login_ids
}
