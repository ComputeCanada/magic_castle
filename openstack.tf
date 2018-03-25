provider "openstack" {
  user_name   = "${var.os_username}"
  password    = "${var.os_password}"
  auth_url    = "${var.os_auth_url}"
  tenant_name = "${var.os_tenant_name}"
  tenant_id   = "${var.os_tenant_id}"
  region      = "${var.os_region_name}"
}

data "template_file" "common" {
  template = "${file("common.yaml")}"

  vars {
    nb_nodes      = "${var.nb_nodes}"
    compute_vcpus = "${var.compute_vcpus}"
    compute_ram   = "${var.compute_ram - 256}"
    compute_disk  = "${var.compute_disk}"
  }
}

data "template_file" "login" {
  template = "${file("login.yaml")}"

  vars {
    nb_nodes = "${var.nb_nodes}"
  }
}

data "template_cloudinit_config" "login_config" {
  part {
    filename     = "login.yaml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.login.rendered}"
  }

  part {
    filename     = "common.yaml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.common.rendered}"
  }
}

resource "openstack_compute_instance_v2" "login1" {
  name            = "login1"
  flavor_id       = "${var.os_login_flavor_id}"
  key_pair        = "${var.os_ssh_key}"
  security_groups = ["default", "ssh"]
  user_data       = "${data.template_cloudinit_config.login_config.rendered}"

  block_device {
    uuid                  = "${var.os_image_id}"
    source_type           = "image"
    volume_size           = 20
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    name = "${var.os_default_network}"
  }
}

data "template_file" "node" {
  template = "${file("node.yaml")}"

  vars {
    login1_ip = "${openstack_compute_instance_v2.login1.network.0.fixed_ip_v4}"
  }
}

data "openstack_compute_flavor_v2" "node" {
  vcpus = "${var.compute_vcpus}"
  ram   = "${var.compute_ram}"
  disk  = "${var.compute_disk}"
}

data "template_cloudinit_config" "node_config" {
  part {
    filename     = "node.yaml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.node.rendered}"
  }

  part {
    filename     = "common.yaml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.common.rendered}"
  }
}

resource "openstack_compute_instance_v2" "node" {
  count    = "${var.nb_nodes}"
  name     = "compute_node${count.index + 1}"
  image_id = "${var.os_image_id}"

  # flavor_id       = "${var.os_flavor_id}"
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
  instance_id = "${openstack_compute_instance_v2.login1.id}"
}

output "ip" {
  value = "${openstack_networking_floatingip_v2.fip_1.address}"
}
