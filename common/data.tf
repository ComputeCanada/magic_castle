locals {
  domain_name = "${var.cluster_name}.${var.domain}"
}

resource "random_string" "munge_key" {
  length  = 32
  special = false
}

resource "random_string" "puppetmaster_password" {
  length  = 32
  special = false
}

resource "random_string" "freeipa_passwd" {
  length  = 16
  special = false
}

resource "random_pet" "guest_passwd" {
  count     = var.guest_passwd != "" ? 0 : 1
  length    = 4
  separator = "."
}

data "http" "hieradata_template" {
  url = "${replace(var.puppetenv_git, ".git", "")}/raw/${var.puppetenv_rev}/data/common.yaml.tmpl"
}

data "template_file" "hieradata" {
  template = data.http.hieradata_template.body

  vars = {
    sudoer_username       = var.sudoer_username
    freeipa_passwd        = random_string.freeipa_passwd.result
    cluster_name          = var.cluster_name
    domain_name           = local.domain_name
    guest_passwd          = var.guest_passwd != "" ? var.guest_passwd : random_pet.guest_passwd[0].id
    munge_key             = base64sha512(random_string.munge_key.result)
    nb_users              = var.nb_users
    freeipa_ip            = local.mgmt01_ip
    nfs_ip                = local.mgmt01_ip
    rsyslog_ip            = local.mgmt01_ip
    slurmctld_ip          = local.mgmt01_ip
    slurmdbd_ip           = local.mgmt01_ip
    squid_ip              = local.mgmt01_ip
  }
}

data "template_file" "mgmt" {
  template = file("${path.module}/cloud-init/mgmt.yaml")
  count    = var.nb_mgmt

  vars = {
    puppetenv_git         = "${replace(replace(var.puppetenv_git, ".git", ""), "//*$/", ".git")}"
    puppetenv_rev         = var.puppetenv_rev
    puppetmaster          = local.mgmt01_ip
    puppetmaster_password = random_string.puppetmaster_password.result
    hieradata             = indent(6, data.template_file.hieradata.rendered)
    node_name             = format("mgmt%02d", count.index + 1)
    sudoer_username       = var.sudoer_username
    ssh_authorized_keys   = "[${file(var.public_key_path)}]"
    home_dev              = local.home_dev
    project_dev           = local.project_dev
    scratch_dev           = local.scratch_dev
  }
}

data "template_cloudinit_config" "mgmt_config" {
  count = var.nb_mgmt

  part {
    filename     = "mgmt.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = data.template_file.mgmt[count.index].rendered
  }
}

data "template_file" "login" {
  template = file("${path.module}/cloud-init/puppet.yaml")
  count    = var.nb_login

  vars = {
    node_name             = format("login%02d", count.index + 1)
    sudoer_username       = var.sudoer_username
    ssh_authorized_keys   = "[${file(var.public_key_path)}]"
    puppetmaster          = local.mgmt01_ip
    puppetmaster_password = random_string.puppetmaster_password.result
  }
}

resource "tls_private_key" "login_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "template_cloudinit_config" "login_config" {
  count = var.nb_login

  part {
    filename     = "login.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = data.template_file.login[count.index].rendered
  }
  part {
    filename     = "ssh_keys.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = <<EOF
ssh_keys:
  rsa_private: |
    ${indent(4, tls_private_key.login_rsa.private_key_pem)}
  rsa_public: |
    ${tls_private_key.login_rsa.public_key_openssh}

EOF

  }
}

data "template_file" "node" {
  template = file("${path.module}/cloud-init/puppet.yaml")
  count = var.nb_nodes

  vars = {
    node_name             = "node${count.index + 1}"
    sudoer_username       = var.sudoer_username
    ssh_authorized_keys   = "[${file(var.public_key_path)}]"
    puppetmaster          = local.mgmt01_ip
    puppetmaster_password = random_string.puppetmaster_password.result
  }
}

data "template_cloudinit_config" "node_config" {
  count = var.nb_nodes
  part {
    filename     = "node.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = data.template_file.node[count.index].rendered
  }
}
