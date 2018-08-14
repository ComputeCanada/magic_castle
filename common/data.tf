resource "random_string" "admin_passwd" {
  length  = 16
  special = false
}

resource "random_pet" "guest_passwd" {
  length    = 4
  separator = "."
}

data "template_file" "common" {
  template = "${file("${path.module}/cloud-init/common.yaml")}"

  vars {
    cluster_name = "${var.cluster_name}"
    munge_key    = "${base64sha512(random_string.admin_passwd.result)}"
  }
}

data "template_file" "mgmt" {
  template = "${file("${path.module}/cloud-init/mgmt.yaml")}"

  vars {
    admin_passwd = "${random_string.admin_passwd.result}"
    domain_name  = "${var.domain_name}"
    cidr         = "${local.cidr}"
    guest_passwd = "${random_pet.guest_passwd.id}"
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
  template = "${file("${path.module}/cloud-init/login.yaml")}"

  vars {
    admin_passwd = "${random_string.admin_passwd.result}"
    mgmt01_ip    = "${local.mgmt01_ip}"
    hostname     = "${var.cluster_name}01"
    domain_name  = "${var.domain_name}"
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
  template = "${file("${path.module}/cloud-init/node.yaml")}"
  count    = "${var.nb_nodes}"

  vars {
    admin_passwd = "${random_string.admin_passwd.result}"
    domain_name  = "${var.domain_name}"
    mgmt01_ip    = "${local.mgmt01_ip}"
    hostname     = "node${count.index + 1}"
  }
}

data "template_cloudinit_config" "node_config" {
  count = "${var.nb_nodes}"

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
    content      = "${element(data.template_file.node.*.rendered, count.index)}"
  }
}
