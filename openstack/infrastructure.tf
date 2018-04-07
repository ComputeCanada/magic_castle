provider "openstack" {}

resource "openstack_compute_instance_v2" "mgmt01" {
  name            = "mgmt01"
  flavor_id       = "${var.os_mgmt_flavor_id}"
  key_pair        = "${var.os_ssh_key}"
  security_groups = ["default"]
  user_data       = "${data.template_cloudinit_config.mgmt_config.rendered}"

  block_device {
    uuid                  = "${var.os_image_id}"
    source_type           = "image"
    volume_size           = "${var.shared_storage_size}"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    name = "${var.os_default_network}"
  }
}

locals {
  mgmt01_ip = "${openstack_compute_instance_v2.mgmt01.network.0.fixed_ip_v4}"
}

resource "openstack_compute_instance_v2" "login01" {
  name     = "${var.cluster_name}01"
  image_id = "${var.os_image_id}"

  flavor_id       = "${var.os_login_flavor_id}"
  key_pair        = "${var.os_ssh_key}"
  security_groups = ["default", "ssh"]
  user_data       = "${data.template_cloudinit_config.login_config.rendered}"

  network {
    name = "${var.os_default_network}"
  }
}

resource "openstack_compute_instance_v2" "node" {
  count    = "${var.nb_nodes}"
  name     = "node${count.index + 1}"
  image_id = "${var.os_image_id}"

  flavor_id       = "${data.openstack_compute_flavor_v2.node.id}"
  key_pair        = "${var.os_ssh_key}"
  security_groups = ["default"]
  user_data       = "${data.template_cloudinit_config.node_config.rendered}"

  network {
    name = "${var.os_default_network}"
  }
}

resource "openstack_networking_floatingip_v2" "fip_1" {
  pool = "${var.os_external_network}"
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = "${openstack_networking_floatingip_v2.fip_1.address}"
  instance_id = "${openstack_compute_instance_v2.login01.id}"
}

output "ip" {
  value = "${openstack_networking_floatingip_v2.fip_1.address}"
}
