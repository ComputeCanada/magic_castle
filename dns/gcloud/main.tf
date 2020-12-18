provider "google" {
}

data "google_dns_managed_zone" "domain" {
  name    = var.zone_name
  project = var.project
}

module "record_generator" {
  source         = "../record_generator"
  name           = lower(var.name)
  login_ips      = var.public_ip
  rsa_public_key = var.rsa_public_key
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

module "acme" {
  source              = "../acme"
  dns_provider        = "gcloud"
  dns_provider_config = { GCE_PROJECT = var.project }
  name                = lower(var.name)
  domain              = var.domain
  email               = var.email
  sudoer_username     = var.sudoer_username
  login_ips           = var.public_ip
  login_ids           = var.login_ids
  ssh_private_key     = var.ssh_private_key
}

output "hostnames" {
  value = distinct(compact([for record in module.record_generator.records : join(".", [record.name, var.domain]) if record.type == "A" ]))
}
