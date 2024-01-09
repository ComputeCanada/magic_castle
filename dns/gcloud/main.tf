provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

data "google_dns_managed_zone" "domain" {
  name    = var.zone_name
  project = var.project
}

module "dkim" {
  source           = "../dkim"
  sudoer_username  = var.sudoer_username
  public_instances = var.public_instances
  ssh_private_key  = var.ssh_private_key
}

module "record_generator" {
  source         = "../record_generator"
  name           = lower(var.name)
  public_instances = var.public_instances
  vhosts           = var.vhosts
  domain_tag       = var.domain_tag
  vhost_tag        = var.vhost_tag
  dkim_public_key  = module.dkim.public_key
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
  count               = var.issue_wildcard_cert ? 1 : 0
  source              = "../acme"
  dns_provider        = "gcloud"
  dns_provider_config = {
    GCE_PROJECT = var.project
  }
  name                = lower(var.name)
  domain              = var.domain
  email               = var.email
  sudoer_username     = var.sudoer_username
  bastions            = var.bastions
  public_instances    = var.public_instances
  ssh_private_key     = var.ssh_private_key
  ssl_tags            = var.ssl_tags
  acme_key_pem        = var.acme_key_pem
}

output "hostnames" {
  value = distinct(compact([for record in module.record_generator.records : join(".", [record.name, var.domain]) if record.type == "A" ]))
}
