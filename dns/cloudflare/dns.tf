provider "cloudflare" {}

variable "domain_name" {}
variable "public_ip" {}

variable "rsa_public_key" {}

variable "ecdsa_public_key" {}

resource "cloudflare_record" "jupyter" {
  domain = "${join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))}"
  name   = "${element(split(".", var.domain_name), 0)}"
  value  = "${var.public_ip}"
  type   = "A"
}

resource "cloudflare_record" "login_sshfp_rsa_sha1" {
  domain = "${join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))}"
  name   = "${element(split(".", var.domain_name), 0)}"
  type   = "SSHFP"
  data   = {
    algorithm   = 1
    type        = 1
    fingerprint = "${sha1(base64decode(element(split(" ", var.rsa_public_key), 1)))}"
  }
}

resource "cloudflare_record" "login_sshfp_rsa_sha256" {
  domain = "${join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))}"
  name   = "${element(split(".", var.domain_name), 0)}"
  type   = "SSHFP"
  data   = {
    algorithm   = 1
    type        = 2
    fingerprint = "${sha256(base64decode(element(split(" ", var.rsa_public_key), 1)))}"
  }
}

resource "cloudflare_record" "login_sshfp_ecdsa_sha1" {
  domain = "${join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))}"
  name   = "${element(split(".", var.domain_name), 0)}"
  type   = "SSHFP"
  data   = {
    algorithm   = 3
    type        = 1
    fingerprint = "${sha1(base64decode(element(split(" ", var.ecdsa_public_key), 1)))}"
  }
}

resource "cloudflare_record" "login_sshfp_ecdsa_sha256" {
  domain = "${join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))}"
  name   = "${element(split(".", var.domain_name), 0)}"
  type   = "SSHFP"
  data   = {
    algorithm   = 3
    type        = 2
    fingerprint = "${sha256(base64decode(element(split(" ", var.ecdsa_public_key), 1)))}"
  }
}
