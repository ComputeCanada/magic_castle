provider "cloudflare" {}
variable "name" {}
variable "domain" {}
variable "public_ip" {}
variable "rsa_public_key" {}
variable "ecdsa_public_key" {}

resource "cloudflare_record" "jupyter" {
  domain = "${var.domain}"
  name   = "${var.name}"
  value  = "${var.public_ip}"
  type   = "A"
}

resource "cloudflare_record" "login_sshfp_rsa_sha1" {
  domain = "${var.domain}"
  name   = "${var.name}"
  type   = "SSHFP"
  data   = {
    algorithm   = 1
    type        = 1
    fingerprint = "${sha1(base64decode(element(split(" ", var.rsa_public_key), 1)))}"
  }
}

resource "cloudflare_record" "login_sshfp_rsa_sha256" {
  domain = "${var.domain}"
  name   = "${var.name}"
  type   = "SSHFP"
  data   = {
    algorithm   = 1
    type        = 2
    fingerprint = "${sha256(base64decode(element(split(" ", var.rsa_public_key), 1)))}"
  }
}

resource "cloudflare_record" "login_sshfp_ecdsa_sha1" {
  domain = "${var.domain}"
  name   = "${var.name}"
  type   = "SSHFP"
  data   = {
    algorithm   = 3
    type        = 1
    fingerprint = "${sha1(base64decode(element(split(" ", var.ecdsa_public_key), 1)))}"
  }
}

resource "cloudflare_record" "login_sshfp_ecdsa_sha256" {
  domain = "${var.domain}"
  name   = "${var.name}"
  type   = "SSHFP"
  data   = {
    algorithm   = 3
    type        = 2
    fingerprint = "${sha256(base64decode(element(split(" ", var.ecdsa_public_key), 1)))}"
  }
}
