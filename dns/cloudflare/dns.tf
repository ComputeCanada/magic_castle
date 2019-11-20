provider "cloudflare" {
  version = "~> 2.0"
}

variable "name" {
}

variable "domain" {
}

data "cloudflare_zones" "domain" {
  filter {
    name   = var.domain
    status = "active"
    paused = false
  }
}

variable "public_ip" {
  type = list(string)
}

variable "rsa_public_key" {
}

data "external" "key2fp" {
  program = ["python", "${path.module}/key2fp.py"]
  query = {
    ssh_key = var.rsa_public_key
  }
}

resource "cloudflare_record" "loginX_A" {
  count   = length(var.public_ip)
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = join("", [var.name, format("%d", count.index + 1)])
  value   = var.public_ip[count.index]
  type    = "A"
}

resource "cloudflare_record" "loginX_sshfp_rsa_sha256" {
  count   = length(var.public_ip)
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = join("", [var.name, format("%d", count.index + 1)])
  type    = "SSHFP"
  data    = {
    algorithm   = data.external.key2fp.result["algorithm"]
    type        = 2
    fingerprint = data.external.key2fp.result["sha256"]
  }
}

resource "cloudflare_record" "login_A" {
  count   = max(length(var.public_ip), 1)
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = var.name
  value   = var.public_ip[count.index]
  type    = "A"
}

resource "cloudflare_record" "jupyter_A" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = "jupyter.${var.name}"
  value   = var.public_ip[0]
  type    = "A"
}

resource "cloudflare_record" "login_sshfp_rsa_sha256" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = var.name
  type    = "SSHFP"
  data    = {
    algorithm   = data.external.key2fp.result["algorithm"]
    type        = 2
    fingerprint = data.external.key2fp.result["sha256"]
  }
}

output "hostnames" {
  value = concat(
    [cloudflare_record.login_A[0].hostname],
    cloudflare_record.loginX_A[*].hostname,
  )
}
