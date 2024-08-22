data "google_dns_managed_zone" "domain" {
  name    = var.zone_name
  project = var.project
}

module "record_generator" {
  source         = "../record_generator"
  name           = lower(var.name)
  public_instances = var.public_instances
  vhosts           = var.vhosts
  domain_tag       = var.domain_tag
  vhost_tag        = var.vhost_tag
}

resource "google_dns_record_set" "records" {
  count        = length(module.record_generator.records)
  managed_zone = data.google_dns_managed_zone.domain.name
  project      = var.project
  name         = join(".", [module.record_generator.records[count.index].name, var.domain, ""])
  type         = module.record_generator.records[count.index].type
  rrdatas      = [module.record_generator.records[count.index].type != "SSHFP" ?
                  module.record_generator.records[count.index].value :
                  join(" ", [module.record_generator.records[count.index].data["algorithm"],
                             module.record_generator.records[count.index].data["type"],
                             module.record_generator.records[count.index].data["fingerprint"]])
                 ]
  ttl          = 300
}

output "hostnames" {
  value = distinct(compact([for record in module.record_generator.records : join(".", [record.name, var.domain]) if record.type == "A" ]))
}
