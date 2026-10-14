data "openstack_dns_zone_v2" "domain" {
  name = coalesce(var.zone_name, "${var.domain}.")
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

locals {
  # Designate holds one record set per name and type, so records sharing
  # a name and a type (several login nodes, SSHFP algorithms, TXT records)
  # are grouped into a single record set.
  record_values = {
    for record in module.record_generator.records :
    "${record.name} ${record.type}" => (
      record.type == "SSHFP" ?
      join(" ", [record.data["algorithm"], record.data["type"], record.data["fingerprint"]]) :
      record.value
    )...
  }
}

resource "openstack_dns_recordset_v2" "records" {
  for_each = local.record_values
  zone_id  = data.openstack_dns_zone_v2.domain.id
  name     = "${split(" ", each.key)[0]}.${var.domain}."
  type     = split(" ", each.key)[1]
  ttl      = var.ttl
  records  = distinct(each.value)
}

output "hostnames" {
  value = distinct(compact([for record in module.record_generator.records : join(".", [record.name, var.domain]) if record.type == "A"]))
}

output "recordsets" {
  description = "Record sets created in the Designate zone, keyed by record name and type."
  value       = { for key, rs in openstack_dns_recordset_v2.records : key => { name = rs.name, type = rs.type, ttl = rs.ttl, zone_id = rs.zone_id, records = rs.records } }
}
