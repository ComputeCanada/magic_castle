data "cloudflare_zones" "domain" {
  name   = var.domain
  status = "active"
}

module "record_generator" {
  source           = "../record_generator"
  name             = lower(var.name)
  public_instances = var.public_instances
  vhosts           = var.vhosts
  domain_tag       = var.domain_tag
  vhost_tag        = var.vhost_tag
  dkim_public_key  = var.dkim_public_key
}

resource "cloudflare_dns_record" "records" {
  count   = length(module.record_generator.records)
  zone_id = data.cloudflare_zones.domain.result[0].id
  name    = module.record_generator.records[count.index].name
  content = module.record_generator.records[count.index].value
  type    = module.record_generator.records[count.index].type
  ttl     = 1
  data    = module.record_generator.records[count.index].data
}

output "hostnames" {
  value = distinct(compact([for record in module.record_generator.records : join(".", [record.name, var.domain]) if record.type == "A"]))
}
