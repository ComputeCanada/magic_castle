resource "incus_network" "network" {
  name    = incus_project.project.name
  project = incus_project.project.name
  config = {
    "ipv4.nat"     = "true"
    "ipv6.address" = "none"
  }
}
