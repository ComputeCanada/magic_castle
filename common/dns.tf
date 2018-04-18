provider "cloudflare" {}

resource "cloudflare_record" "jupyter" {
  domain = "${join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))}"
  name   = "${element(split(".", var.domain_name), 0)}"
  value  = "${local.public_ip}"
  type   = "A"
  ttl    = 3600
}
