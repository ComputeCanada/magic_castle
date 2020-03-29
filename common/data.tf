locals {
  domain_name = "${lower(var.cluster_name)}.${lower(var.domain)}"
  node = {
    for item in flatten([
      for node in var.instances["node"]: [
        for j in range(node.count): {
          (
            lookup(node, "prefix", "") != "" ?
            format("%s-node%d", lookup(node, "prefix", ""), j+1) :
            format("node%d", j+1)
          ) = {
            for key in setsubtract(keys(node), ["prefix", "count"]):
              key => node[key]
          }
        }
      ]
    ]):
    keys(item)[0] => values(item)[0]
  }
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

resource "random_uuid" "consul_token" { }

data "http" "hieradata_template" {
  url = "${replace(var.puppetenv_git, ".git", "")}/raw/${var.puppetenv_rev}/data/terraform_data.yaml.tmpl"
}

data "template_file" "hieradata" {
  template = data.http.hieradata_template.body

  vars = {
    sudoer_username = var.sudoer_username
    freeipa_passwd  = random_string.freeipa_passwd.result
    cluster_name    = var.cluster_name
    domain_name     = local.domain_name
    guest_passwd    = var.guest_passwd != "" ? var.guest_passwd : random_pet.guest_passwd[0].id
    consul_token    = random_uuid.consul_token.result
    munge_key       = base64sha512(random_string.munge_key.result)
    nb_users        = var.nb_users
    mgmt1_ip        = local.mgmt1_ip
    home_size       = "${var.storage["home_size"]}G"
    project_size    = "${var.storage["project_size"]}G"
    scratch_size    = "${var.storage["scratch_size"]}G"
  }
}

data "template_cloudinit_config" "mgmt_config" {
  count = var.instances["mgmt"]["count"]
  part {
    filename     = "mgmt.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = templatefile(
      format("${path.module}/cloud-init/%s.yaml", count.index == 0 ? "puppetmaster": "puppetagent"),
      {
        puppetenv_git         = replace(replace(var.puppetenv_git, ".git", ""), "//*$/", ".git"),
        puppetenv_rev         = var.puppetenv_rev,
        puppetmaster_ip       = local.puppetmaster_ip,
        puppetmaster_password = random_string.puppetmaster_password.result,
        hieradata             = data.template_file.hieradata.rendered,
        user_hieradata        = var.hieradata,
        node_name             = format("mgmt%d", count.index + 1),
        sudoer_username       = var.sudoer_username,
        ssh_authorized_keys   = var.public_keys,
      }
    )
  }
}

resource "tls_private_key" "login_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "template_cloudinit_config" "login_config" {
  count = var.instances["login"]["count"]

  part {
    filename     = "ssh_keys.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = <<EOF
runcmd:
  - chmod 644 /etc/ssh/ssh_host_rsa_key.pub
  - chgrp ssh_keys /etc/ssh/ssh_host_rsa_key.pub
ssh_keys:
  rsa_private: |
    ${indent(4, tls_private_key.login_rsa.private_key_pem)}
  rsa_public: |
    ${tls_private_key.login_rsa.public_key_openssh}
EOF
  }
  part {
    filename     = "login.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = templatefile(
      "${path.module}/cloud-init/puppetagent.yaml",
      {
        node_name             = format("login%d", count.index + 1),
        sudoer_username       = var.sudoer_username,
        ssh_authorized_keys   = var.public_keys,
        puppetmaster_ip       = local.puppetmaster_ip,
        puppetmaster_password = random_string.puppetmaster_password.result,
      }
    )
  }
}

data "template_cloudinit_config" "node_config" {
  for_each = local.node
  part {
    filename     = "node.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = templatefile(
      "${path.module}/cloud-init/puppetagent.yaml",
      {
        node_name             = each.key,
        sudoer_username       = var.sudoer_username,
        ssh_authorized_keys   = var.public_keys,
        puppetmaster_ip       = local.puppetmaster_ip,
        puppetmaster_password = random_string.puppetmaster_password.result,
      }
    )
  }
}
