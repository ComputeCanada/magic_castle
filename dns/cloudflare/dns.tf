provider "cloudflare" {
}

variable "name" {
}

variable "domain" {
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
  count  = length(var.public_ip)
  domain = var.domain
  name   = join("", [var.name, format("%d", count.index + 1)])
  value  = var.public_ip[count.index]
  type   = "A"
}

resource "cloudflare_record" "loginX_sshfp_rsa_sha1" {
  count  = length(var.public_ip)
  domain = var.domain
  name   = join("", [var.name, format("%d", count.index + 1)])
  type   = "SSHFP"
  data = {
    algorithm   = data.external.key2fp.result["algorithm"]
    type        = 1
    fingerprint = data.external.key2fp.result["sha1"]
  }
}

resource "cloudflare_record" "loginX_sshfp_rsa_sha256" {
  count  = length(var.public_ip)
  domain = var.domain
  name   = join("", [var.name, format("%d", count.index + 1)])
  type   = "SSHFP"
  data = {
    algorithm   = data.external.key2fp.result["algorithm"]
    type        = 2
    fingerprint = data.external.key2fp.result["sha256"]
  }
}

resource "cloudflare_record" "login_A" {
  count  = max(length(var.public_ip), 1)
  domain = var.domain
  name   = var.name
  value  = var.public_ip[count.index]
  type   = "A"
}

resource "cloudflare_record" "jupyter_A" {
  domain = var.domain
  name   = "jupyter.${var.name}"

  value = var.public_ip[0]
  type  = "A"
}

resource "cloudflare_record" "login_sshfp_rsa_sha1" {
  domain = var.domain
  name   = var.name
  type   = "SSHFP"
  data = {
    algorithm   = data.external.key2fp.result["algorithm"]
    type        = 1
    fingerprint = data.external.key2fp.result["sha1"]
  }
}

resource "cloudflare_record" "login_sshfp_rsa_sha256" {
  domain = var.domain
  name   = var.name
  type   = "SSHFP"
  data = {
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
