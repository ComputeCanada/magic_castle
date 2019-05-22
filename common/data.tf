resource "random_string" "admin_passwd" {
  length  = 16
  special = false
}

resource "random_pet" "guest_passwd" {
  length    = 4
  separator = "."
}

data "template_file" "mgmt" {
  template = "${file("${path.module}/cloud-init/mgmt.yaml")}"
  vars {
    home_dev    = "${local.home_dev}"
    project_dev = "${local.project_dev}"
    scratch_dev = "${local.scratch_dev}"
  }
}

data "template_file" "mgmt_data" {
  template = "${file("${local.data_path}")}"

  vars {
    admin_passwd    = "${random_string.admin_passwd.result}"
    cluster_name    = "${var.cluster_name}"
    dns_ip          = ""
    domain_name     = "${local.domain_name}"
    guest_passwd    = "${random_pet.guest_passwd.id}"
    munge_key       = "${base64sha512(random_string.admin_passwd.result)}"
    nb_users        = "${var.nb_users}"
  }
}

data "template_file" "mgmt_puppet" {
  template = "${file("${path.module}/cloud-init/puppet.yaml")}"
  count    = "${var.nb_mgmt}"

  vars {
    node_name       = "${format("mgmt%02d", count.index + 1)}"
    email           = "${var.email}"
    puppetfile      = "${indent(6, file("${local.puppetfile_path}"))}"
    site_pp         = "${indent(6, file("${local.site_pp_path}"))}"
    data            = "${indent(6, "${data.template_file.mgmt_data.rendered}")}"
  }
}

data "template_cloudinit_config" "mgmt_config" {
  count    = "${var.nb_mgmt}"

  part {
    filename     = "mgmt.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${data.template_file.mgmt.rendered}"
  }
  part {
    filename     = "mgmt_puppet.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${element(data.template_file.mgmt_puppet.*.rendered, count.index)}"
  }
}

data "template_file" "login_data" {
  template = "${file("${local.data_path}")}"

  vars {
    admin_passwd    = "${random_string.admin_passwd.result}"
    cluster_name    = "${var.cluster_name}"
    dns_ip          = "${local.mgmt01_ip}"
    domain_name     = "${local.domain_name}"
    guest_passwd    = "${random_pet.guest_passwd.id}"
    munge_key       = "${base64sha512(random_string.admin_passwd.result)}"
    nb_users        = ""
  }
}

data "template_file" "login" {
  template = "${file("${path.module}/cloud-init/puppet.yaml")}"
  count    = "${var.nb_login}"

  vars {
    node_name  = "${format("login%02d", count.index + 1)}"
    email      = "${var.email}"
    puppetfile = "${indent(6, file("${local.puppetfile_path}"))}"
    site_pp    = "${indent(6, file("${local.site_pp_path}"))}"
    data       = "${indent(6, "${data.template_file.login_data.rendered}")}"
  }
}

resource "tls_private_key" "login_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "template_cloudinit_config" "login_config" {
  count          = "${var.nb_login}"

  part {
    filename     = "login.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${element(data.template_file.login.*.rendered, count.index)}"
  }
  part {
    filename     = "ssh_keys.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = <<EOF
ssh_keys:
  rsa_private: |
    ${indent(4, tls_private_key.login_rsa.private_key_pem)}
  rsa_public: "${tls_private_key.login_rsa.public_key_openssh} "
 EOF
  }
}

data "template_file" "node_data" {
  template = "${file("${local.data_path}")}"

  vars {
    admin_passwd    = "${random_string.admin_passwd.result}"
    cluster_name    = "${var.cluster_name}"
    dns_ip          = "${local.mgmt01_ip}"
    domain_name     = "${local.domain_name}"
    guest_passwd    = "${random_pet.guest_passwd.id}"
    munge_key       = "${base64sha512(random_string.admin_passwd.result)}"
    nb_users        = ""
  }
}

data "template_file" "node" {
  template = "${file("${path.module}/cloud-init/puppet.yaml")}"
  count    = "${var.nb_nodes}"

  vars {
    node_name       = "node${count.index + 1}"
    email           = "${var.email}"
    puppetfile      = "${indent(6, file("${local.puppetfile_path}"))}"
    site_pp         = "${indent(6, file("${local.site_pp_path}"))}"
    data            = "${indent(6, "${data.template_file.node_data.rendered}")}"
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
