data "template_file" "common" {
  template = "${file("common.yaml")}"

  vars {
    nb_nodes      = "${var.nb_nodes}"
    compute_vcpus = "${var.compute_vcpus}"
    compute_ram   = "${floor(var.compute_ram * 0.925)}"
    compute_disk  = "${var.compute_disk}"
    cluster_name  = "${var.cluster_name}"
  }
}

data "template_file" "mgmt" {
  template = "${file("mgmt.yaml")}"

  vars {
    admin_passwd = "${var.admin_passwd}"
    guest_passwd = "${var.guest_passwd}"
    nb_users     = "${var.nb_users}"
  }
}

data "template_cloudinit_config" "mgmt_config" {
  part {
    filename     = "common.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${data.template_file.common.rendered}"
  }

  part {
    filename     = "mgmt.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${data.template_file.mgmt.rendered}"
  }
}

data "template_file" "login" {
  template = "${file("login.yaml")}"

  vars {
    admin_passwd = "${var.admin_passwd}"
    mgmt01_ip    = "${openstack_compute_instance_v2.mgmt01.network.0.fixed_ip_v4}"
  }
}

data "template_cloudinit_config" "login_config" {
  part {
    filename     = "common.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${data.template_file.common.rendered}"
  }

  part {
    filename     = "login.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${data.template_file.login.rendered}"
  }
}

data "template_file" "node" {
  template = "${file("node.yaml")}"

  vars {
    admin_passwd = "${var.admin_passwd}"
    mgmt01_ip    = "${openstack_compute_instance_v2.mgmt01.network.0.fixed_ip_v4}"
  }
}

data "openstack_compute_flavor_v2" "node" {
  vcpus = "${var.compute_vcpus}"
  ram   = "${var.compute_ram}"
  disk  = "${var.compute_disk}"
}

data "template_cloudinit_config" "node_config" {
  part {
    filename     = "common.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${data.template_file.common.rendered}"
  }

  part {
    filename     = "node.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${data.template_file.node.rendered}"
  }
}
