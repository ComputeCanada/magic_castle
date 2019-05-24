provider "cloudflare" {}
variable "name" {}
variable "domain" {}
variable "public_ip" {
  type = "list"
}
variable "rsa_public_key" {}

variable "nb_login" {}

resource "cloudflare_record" "login_record" {
  count  = "${var.nb_login}"
  domain = "${var.domain}"
  name   = "${join("", list(var.name, format("%d", count.index + 1)))}"
  value  = "${element(var.public_ip, count.index)}"
  type   = "A"
}

resource "cloudflare_record" "login_sshfp_rsa_sha1" {
  count  = "${var.nb_login}"
  domain = "${var.domain}"
  name   = "${join("", list(var.name, format("%d", count.index + 1)))}"
  type   = "SSHFP"
  data   = {
    algorithm   = 1
    type        = 1
    fingerprint = "${sha1(base64decode(element(split(" ", var.rsa_public_key), 1)))}"
  }
}

resource "cloudflare_record" "login_sshfp_rsa_sha256" {
  count  = "${var.nb_login}"
  domain = "${var.domain}"
  name   = "${join("", list(var.name, format("%d", count.index + 1)))}"
  type   = "SSHFP"
  data   = {
    algorithm   = 1
    type        = 2
    fingerprint = "${sha256(base64decode(element(split(" ", var.rsa_public_key), 1)))}"
  }
}

resource "cloudflare_record" "login01_cname" {
  domain = "${var.domain}"
  name   = "${var.name}"
  value  = "${var.name}1.${var.domain}"
  type   = "CNAME"
}

output "hostnames" {
  value = "${concat(list(cloudflare_record.login01_cname.hostname), cloudflare_record.login_record.*.hostname)}"
}