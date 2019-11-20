provider "google" {
  version = "< 3.0.0"
}

data "google_dns_managed_zone" "domain" {
  name    = var.zone_name
  project = var.project
}

data "external" "key2fp" {
  program = ["python", "${path.module}/../key2fp.py"]
  query = {
    ssh_key = var.rsa_public_key
  }
}

resource "google_dns_record_set" "loginX_A" {
  count        = length(var.public_ip)
  managed_zone = data.google_dns_managed_zone.domain.name
  project      = var.project
  name         = join(".", [format("login%d", count.index + 1), var.name, var.domain, ""])
  rrdatas      = [var.public_ip[count.index]]
  ttl          = 300
  type         = "A"
}

resource "google_dns_record_set" "loginX_sshfp_rsa" {
  count        = length(var.public_ip)
  managed_zone = data.google_dns_managed_zone.domain.name
  project      = var.project
  name         = join(".", [format("login%d", count.index + 1), var.name, var.domain, ""])
  ttl          = 300
  type         = "SSHFP"
  rrdatas      = [join(" ", [data.external.key2fp.result["algorithm"], "2", data.external.key2fp.result["sha256"]])]
}

resource "google_dns_record_set" "login_A" {
  count        = max(length(var.public_ip), 1)
  managed_zone = data.google_dns_managed_zone.domain.name
  project      = var.project
  name         = join(".", [var.name, var.domain, ""])
  ttl          = 300
  type         = "A"
  rrdatas      = [var.public_ip[count.index]]
}

resource "google_dns_record_set" "jupyter_A" {
  managed_zone = data.google_dns_managed_zone.domain.name
  project      = var.project
  name         = join(".", ["jupyter", var.name, var.domain, ""])
  ttl          = 300
  type         = "A"
  rrdatas      = [var.public_ip[0]]
}

resource "google_dns_record_set" "login_sshfp_rsa" {
  managed_zone = data.google_dns_managed_zone.domain.name
  project      = var.project
  name         = join(".", [var.name, var.domain, ""])
  ttl          = 300
  type         = "SSHFP"
  rrdatas      = [join(" ", [data.external.key2fp.result["algorithm"], "2", data.external.key2fp.result["sha256"]])]
}

output "hostnames" {
  value = concat(
    [google_dns_record_set.login_A[0].name],
    google_dns_record_set.loginX_A[*].name,
  )
}
