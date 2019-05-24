provider "cloudflare" {}
variable "name" {}
variable "domain" {}
variable "public_ip" {
  type = "list"
}
variable "rsa_public_key" {}

resource "cloudflare_record" "login_record" {
  count  = "${length(var.public_ip)}"
  domain = "${var.domain}"
  name   = "${format(var.name + "%d", count.index + 1)}"
  value  = "${element(var.public_ip, count.index)}"
  type   = "A"
}

resource "cloudflare_record" "login_sshfp_rsa_sha1" {
  count  = "${length(var.public_ip)}"
  domain = "${var.domain}"
  name   = "${format(var.name + "%d", count.index + 1)}"
  type   = "SSHFP"
  data   = {
    algorithm   = 1
    type        = 1
    fingerprint = "${sha1(base64decode(element(split(" ", var.rsa_public_key), 1)))}"
  }
}

resource "cloudflare_record" "login_sshfp_rsa_sha256" {
  count  = "${length(var.public_ip)}"
  domain = "${var.domain}"
  name   = "${format(var.name + "%d", count.index + 1)}"
  type   = "SSHFP"
  data   = {
    algorithm   = 1
    type        = 2
    fingerprint = "${sha256(base64decode(element(split(" ", var.rsa_public_key), 1)))}"
  }
}

resource "cloudflare_record" "login01_record" {
  domain = "${var.domain}"
  name   = "${var.name}"
  value  = "${var.public_ip.0}"
  type   = "A"
}

resource "cloudflare_record" "login01_sshfp_rsa_sha1" {
  count  = "${length(var.public_ip)}"
  domain = "${var.domain}"
  name   = "${var.name}"
  type   = "SSHFP"
  data   = {
    algorithm   = 1
    type        = 1
    fingerprint = "${sha1(base64decode(element(split(" ", var.rsa_public_key), 1)))}"
  }
}

resource "cloudflare_record" "login01_sshfp_rsa_sha256" {
  domain = "${var.domain}"
  name   = "${var.name}"
  type   = "SSHFP"
  data   = {
    algorithm   = 1
    type        = 2
    fingerprint = "${sha256(base64decode(element(split(" ", var.rsa_public_key), 1)))}"
  }
}

output "domain_name" {
  value = "${var.name}.${var.domain}"
}