resource "incus_network" "network" {
  name    = incus_project.project.name
  project = incus_project.project.name
  type    = var.network_type
  config = merge(
    {
      "ipv6.address" = "none"
      "ipv4.nat"     = true
    },
    var.network_type == "ovn" ? {
      "network"         = var.ovn_uplink_network
      "dns.nameservers" = "1.1.1.1,1.0.0.1" # The default DNS server (incus) is inaccessible from OVN network
    } : {}
  )
}

