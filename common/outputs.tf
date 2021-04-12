output "public_instances" {
  value = module.cluster_config.public_instances
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
  value = module.cluster_config.freeipa_passwd
}

output "guest_usernames" {
  value = "user[${format(format("%%0%dd", length(tostring(var.nb_users))), 1)}-${var.nb_users}]"
}

output "guest_passwd" {
  value = module.cluster_config.guest_passwd
}

output "ssh_private_key" {
  value     = module.instance_config.private_key
  sensitive = true
}