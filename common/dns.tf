provider "cloudflare" {}

resource "cloudflare_record" "jupyter" {
  domain = "${join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))}"
  name   = "${element(split(".", var.domain_name), 0)}"
  value  = "${local.public_ip}"
  type   = "A"
}

resource "cloudflare_record" "login_sshfp_rsa_sha1" {
  name  = "${element(split(".", var.domain_name), 0)}"
  type  = "SSHFP"
  data  = {
    algorithm   = 1
    type        = 1
    fingerprint = "${sha1(base64decode(element(split(" ", tls_private_key.login_rsa.public_key_openssh), 1)))}"
  }
}

resource "cloudflare_record" "login_sshfp_rsa_sha256" {
  name  = "${element(split(".", var.domain_name), 0)}"
  type  = "SSHFP"
  data  = {
    algorithm   = 1
    type        = 2
    fingerprint = "${sha256(base64decode(element(split(" ", tls_private_key.login_rsa.public_key_openssh), 1)))}"
  }
}