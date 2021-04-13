output "guest_passwd" {
  value = var.guest_passwd != "" ? var.guest_passwd : try(random_pet.guest_passwd[0].id, "")
}

output "freeipa_passwd" {
  value = random_string.freeipa_passwd.result
}

output "public_instances" {
  value = local.public_instances
}
