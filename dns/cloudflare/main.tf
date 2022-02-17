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
  public_instances = var.public_instances
  domain_tag       = var.domain_tag
  vhost_tag        = var.vhost_tag
}

resource "cloudflare_record" "records" {
  count   = length(module.record_generator.records)
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = module.record_generator.records[count.index].name
  value   = module.record_generator.records[count.index].value
  type    = module.record_generator.records[count.index].type
  dynamic "data" {
    for_each = module.record_generator.records[count.index].data != null ? [module.record_generator.records[count.index].data] : []
    content {
      algorithm   = data.value["algorithm"]
      fingerprint = data.value["fingerprint"]
      type        = data.value["type"]
    }
  }
}

module "acme" {
  source           = "../acme"
  dns_provider     = "cloudflare"
  name             = lower(var.name)
  domain           = var.domain
  email            = var.email
  sudoer_username  = var.sudoer_username
  public_instances = var.public_instances
  ssh_private_key  = var.ssh_private_key
  ssl_tags         = var.ssl_tags
  acme_key_pem     = var.acme_key_pem
}

output "hostnames" {
  value = distinct(compact([for record in module.record_generator.records : join(".", [record.name, var.domain]) if record.type == "A" ]))
}
