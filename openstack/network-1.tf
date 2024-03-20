data "openstack_networking_network_v2" "ext_network" {
  name     = var.os_ext_network
  external = true
}

data "openstack_networking_subnet_v2" "subnet" {
  subnet_id  = var.subnet_id
  ip_version = 4
}

data "openstack_networking_network_v2" "int_network" {
  network_id = data.openstack_networking_subnet_v2.subnet.network_id
}

locals {
  network = data.openstack_networking_network_v2.int_network
  subnet  = data.openstack_networking_subnet_v2.subnet
}

resource "openstack_networking_floatingip_v2" "fip" {
  for_each = {
    for x, values in module.design.instances : x => true if contains(values.tags, "public") && !contains(keys(var.os_floating_ips), x)
  }
  pool = data.openstack_networking_network_v2.ext_network.name
}

resource "openstack_networking_floatingip_associate_v2" "fip" {
  for_each    = { for x, values in module.design.instances : x => true if contains(values.tags, "public") }
  floating_ip = local.public_ip[each.key]
  port_id     = openstack_networking_port_v2.nic[each.key].id
}

locals {
  public_ip = merge(
    var.os_floating_ips,
    { for x, values in module.design.instances : x => openstack_networking_floatingip_v2.fip[x].address
    if contains(values.tags, "public") && !contains(keys(var.os_floating_ips), x) }
  )
  ext_networks = []
  network_provision_dep = openstack_networking_floatingip_associate_v2.fip
}
