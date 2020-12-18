provider "cloudflare" {
}

data "cloudflare_zones" "domain" {
  filter {
    name   = var.domain
    status = "active"
    paused = false
  }
}

module "record_generator" {
  source         = "../record_generator"
  name           = lower(var.name)
  login_ips      = var.public_ip
  rsa_public_key = var.rsa_public_key
}

resource "cloudflare_record" "records" {
  count   = length(module.record_generator.records)
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = module.record_generator.records[count.index].name
  value   = module.record_generator.records[count.index].value
  type    = module.record_generator.records[count.index].type
  data    = module.record_generator.records[count.index].data
}

module "acme" {
  source           = "../acme"
  dns_provider     = "cloudflare"
  name             = lower(var.name)
  domain           = var.domain
  email            = var.email
  sudoer_username  = var.sudoer_username
  login_ips        = var.public_ip
  login_ids        = var.login_ids
  ssh_private_key  = var.ssh_private_key
}

output "hostnames" {
  value = distinct(compact([for record in module.record_generator.records : join(".", [record.name, var.domain]) if record.type == "A" ]))
}
