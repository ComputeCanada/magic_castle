data "cloudflare_zones" "domain" {
  filter {
    name   = var.domain
    status = "active"
    paused = false
  }
}

module "record_generator" {
  source           = "../record_generator"
  name             = lower(var.name)
  public_instances = var.public_instances
  vhosts           = var.vhosts
  domain_tag       = var.domain_tag
  vhost_tag        = var.vhost_tag
}

resource "cloudflare_record" "records" {
  count   = length(module.record_generator.records)
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = module.record_generator.records[count.index].name
  content = module.record_generator.records[count.index].value
  type    = module.record_generator.records[count.index].type
  dynamic "data" {
    for_each = module.record_generator.records[count.index].data != null ? [module.record_generator.records[count.index].data] : []
    content {
      algorithm   = data.value["algorithm"]
      fingerprint = upper(data.value["fingerprint"])
      type        = data.value["type"]
    }
  }
}

output "hostnames" {
  value = distinct(compact([for record in module.record_generator.records : join(".", [record.name, var.domain]) if record.type == "A"]))
}
