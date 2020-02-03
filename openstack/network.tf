data "openstack_networking_network_v2" "ext_network" {
  name     = var.os_ext_network
  external = true
}

data "openstack_networking_network_v2" "int_network" {
  name     = var.os_int_network
  external = false
}

data "openstack_networking_subnet_v2" "subnet" {
  name       = var.os_int_subnet
  network_id = data.openstack_networking_network_v2.int_network.id
}

locals {
  network = data.openstack_networking_network_v2.int_network
  subnet  = data.openstack_networking_subnet_v2.subnet
}

resource "openstack_networking_floatingip_v2" "fip" {
  count = max(
    max(
      var.instances["login"]["count"] - length(var.os_floating_ips),
      1 - length(var.os_floating_ips),
    ),
    0,
  )
  pool = data.openstack_networking_network_v2.ext_network.name
}

resource "openstack_compute_floatingip_associate_v2" "fip" {
  count = var.instances["login"]["count"]
  floating_ip = local.public_ip[count.index]
  instance_id = openstack_compute_instance_v2.login[count.index].id
}

locals {
  public_ip = concat(
    var.os_floating_ips,
    openstack_networking_floatingip_v2.fip[*].address,
  )
}

locals {
  ext_networks = []
}
