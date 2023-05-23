variable "guest_passwd" { }

resource "random_string" "puppetserver_password" {
  length  = 32
  special = false
}

resource "random_pet" "guest_passwd" {
  count     = var.guest_passwd != "" ? 0 : 1
  length    = 4
  separator = "."
}

output "result" {
    value = {
        puppetserver = random_string.puppetserver_password.result
        guest = var.guest_passwd != "" ? var.guest_passwd : try(random_pet.guest_passwd[0].id, "")
    }
}