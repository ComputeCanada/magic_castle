output "ip" {
  value = "${local.public_ip}"
}

output "domain_name" {
  value = "${var.domain_name}"
}
