resource "incus_network" "network" {
  name = "${var.cluster_name}.${var.domain}"

  config = {
    "ipv4.nat"     = "true"
    "ipv6.nat"     = "false"
  }
}