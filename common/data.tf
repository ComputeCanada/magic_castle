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

data "template_file" "mgmt_puppet" {
  template = "${file("${path.module}/cloud-init/puppet.yaml")}"

  vars {
    admin_passwd    = "${random_string.admin_passwd.result}"
    cluster_name    = "${var.cluster_name}"
    dns_ip          = ""
    domain_name     = "${local.domain_name}"
    guest_passwd    = "${random_pet.guest_passwd.id}"
    munge_key       = "${base64sha512(random_string.admin_passwd.result)}"
    nb_users        = "${var.nb_users}"
    globus_user     = ""
    globus_password = ""
    node_name       = "mgmt01"
  }
}

data "template_cloudinit_config" "mgmt_config" {
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
    content      = "${data.template_file.mgmt_puppet.rendered}"
  }
}

data "template_file" "login" {
  template = "${file("${path.module}/cloud-init/puppet.yaml")}"

  vars {
    admin_passwd    = "${random_string.admin_passwd.result}"
    cluster_name    = "${var.cluster_name}"
    dns_ip          = "${local.mgmt01_ip}"
    domain_name     = "${local.domain_name}"
    guest_passwd    = "${random_pet.guest_passwd.id}"
    munge_key       = "${base64sha512(random_string.admin_passwd.result)}"
    nb_users        = ""
    globus_user     = "${var.globus_user}"
    globus_password = "${var.globus_password}"
    node_name       = "${var.cluster_name}01"
  }
}

resource "tls_private_key" "login_rsa" {
  algorithm   = "RSA"
}

resource "tls_private_key" "login_ecdsa" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

data "template_cloudinit_config" "login_config" {
  part {
    filename     = "login.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = "${data.template_file.login.rendered}"
  }
  part {
    filename     = "ssh_keys.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = <<EOF
ssh_keys:
  rsa_private: |
    ${indent(4, tls_private_key.login_rsa.private_key_pem)}
  rsa_public: ${tls_private_key.login_rsa.public_key_openssh}
  ecdsa_private: |
    ${indent(4, tls_private_key.login_ecdsa.private_key_pem)}
  ecdsa_public: ${tls_private_key.login_ecdsa.public_key_openssh}
 EOF
  }
}

data "template_file" "node" {
  template = "${file("${path.module}/cloud-init/puppet.yaml")}"
  count    = "${var.nb_nodes}"

  vars {
    admin_passwd    = "${random_string.admin_passwd.result}"
    cluster_name    = "${var.cluster_name}"
    dns_ip          = "${local.mgmt01_ip}"
    domain_name     = "${local.domain_name}"
    guest_passwd    = "${random_pet.guest_passwd.id}"
    munge_key       = "${base64sha512(random_string.admin_passwd.result)}"
    nb_users        = ""
    globus_user     = ""
    globus_password = ""
    node_name       = "node${count.index + 1}"
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
