
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
  cidr        = local.cidr
  no_gateway  = true
  enable_dhcp = true
}

resource "openstack_networking_port_v2" "public_nic" {
  for_each              = module.design.instances
  name                  = format("%s-%s-public-port", var.cluster_name, each.key)
  network_id            = data.openstack_networking_network_v2.ext_network.id
  # We concatenate the external tag specific security groups with the
  # cluster global security group to avoid assigning the project
  # default security group when the security group ids list is empty.
  security_group_ids    = concat(
    [
      openstack_networking_secgroup_v2.global.id
    ],
    [
      for tag, value in openstack_networking_secgroup_v2.external: value.id if contains(each.value.tags, tag)
    ]
  )
}

locals {
  network   = openstack_networking_network_v2.int_network
  subnet    = openstack_networking_subnet_v2.subnet
  public_ip = {
    for x, values in module.design.instances :
      x => element([for ip in openstack_networking_port_v2.public_nic[x].all_fixed_ips: ip if ! strcontains(ip, ":")], 0)
      if contains(values.tags, "public")
  }
  ext_networks = [{
    access_network = true,
    name           = data.openstack_networking_network_v2.ext_network.name
  }]
  network_provision_dep = openstack_compute_instance_v2.instances
  cidr = "10.0.1.0/24"
}