resource "random_string" "admin_passwd" {
  length  = 16
  special = false
}

resource "random_pet" "guest_passwd" {
  length    = 4
  separator = "."
}

data "template_file" "mgmt" {
  template = "${file("${path.module}/cloud-init/puppet.yaml")}"

  vars {
    admin_passwd = "${random_string.admin_passwd.result}"
    cluster_name = "${var.cluster_name}"
    dns_ip       = ""
    domain_name  = "${var.domain_name}"
    guest_passwd = "${random_pet.guest_passwd.id}"
    munge_key    = "${base64sha512(random_string.admin_passwd.result)}"
    nb_users     = "${var.nb_users}"
  }
}

data "template_cloudinit_config" "mgmt_config" {
  part {
    filename     = "mgmt.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${data.template_file.mgmt.rendered}"
  }
}

data "template_file" "login" {
  template = "${file("${path.module}/cloud-init/puppet.yaml")}"

  vars {
    admin_passwd = "${random_string.admin_passwd.result}"
    cluster_name = "${var.cluster_name}"
    dns_ip       = "${local.mgmt01_ip}"
    domain_name  = "${var.domain_name}"
    guest_passwd = "${random_pet.guest_passwd.id}"
    munge_key    = "${base64sha512(random_string.admin_passwd.result)}"
    nb_users     = "${var.nb_users}"
  }
}

data "template_cloudinit_config" "login_config" {
  part {
    filename     = "login.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${data.template_file.login.rendered}"
  }
}

data "template_file" "node" {
  template = "${file("${path.module}/cloud-init/puppet.yaml")}"
  count    = "${var.nb_nodes}"

  vars {
    admin_passwd = "${random_string.admin_passwd.result}"
    cluster_name = "${var.cluster_name}"
    dns_ip       = "${local.mgmt01_ip}"
    domain_name  = "${var.domain_name}"
    guest_passwd = "${random_pet.guest_passwd.id}"
    munge_key    = "${base64sha512(random_string.admin_passwd.result)}"
    nb_users     = "${var.nb_users}"
  }
}

data "template_cloudinit_config" "node_config" {
  count = "${var.nb_nodes}"
  part {
    filename     = "node.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${element(data.template_file.node.*.rendered, count.index)}"
  }
}
