output "public_instances" {
  value = local.public_instances
}

output "public_ip" {
  value = {
    for key, values in local.public_instances: key => values["public_ip"]
    if values["public_ip"] != ""
  }
}

output "cluster_name" {
  value = lower(var.cluster_name)
}

output "domain" {
  value = lower(var.domain)
}

output "accounts" {
  value = {
    guests = {
      usernames =   var.nb_users != 0 ? (
        "user[${format(format("%%0%dd", length(tostring(var.nb_users))), 1)}-${var.nb_users}]"
      ) : (
        "You have chosen to create user accounts yourself (`nb_users = 0`), please read the documentation on how to manage this at https://github.com/ComputeCanada/magic_castle/blob/main/docs/README.md#103-add-a-user-account"
      ),
      password = module.configuration.guest_passwd
    }
    sudoer = {
      username = var.sudoer_username
      password = "N/A (public ssh-key auth)"
    }
  }
}

output "ssh_private_key" {
  value     = module.configuration.ssh_key.private
  sensitive = true
}