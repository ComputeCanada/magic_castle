
data "openstack_networking_network_v2" "ext_network" {
  external = true
}

resource "openstack_networking_network_v2" "int_network" {
  name = "${var.cluster_name}_network"
}

resource "openstack_networking_subnet_v2" "subnet" {
  name        = "${var.cluster_name}_subnet"
  network_id  = openstack_networking_network_v2.int_network.id
  ip_version  = 4
  cidr        = "10.0.1.0/24"
  no_gateway  = true
  enable_dhcp = true
}

locals {
  network   = openstack_networking_network_v2.int_network
  subnet    = openstack_networking_subnet_v2.subnet
  public_ip = { for x, values in module.design.instances : x => openstack_compute_instance_v2.instances[x].network[1].fixed_ip_v4 if contains(values.tags, "public") }
  ext_networks = [{
    access_network = true,
    name           = data.openstack_networking_network_v2.ext_network.name
  }]
}