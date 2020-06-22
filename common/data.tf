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

resource "tls_private_key" "ssh" {
  count     = var.generate_ssh_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "http" "hieradata_template" {
  url = "${replace(var.puppetenv_git, ".git", "")}/raw/${var.puppetenv_rev}/data/terraform_data.yaml.tmpl"
}

data "template_file" "hieradata" {
  template = data.http.hieradata_template.body

  vars = {
    sudoer_username = var.sudoer_username
    freeipa_passwd  = random_string.freeipa_passwd.result
    cluster_name    = lower(var.cluster_name)
    domain_name     = local.domain_name
    guest_passwd    = var.guest_passwd != "" ? var.guest_passwd : try(random_pet.guest_passwd[0].id, "")
    consul_token    = random_uuid.consul_token.result
    munge_key       = base64sha512(random_string.munge_key.result)
    nb_users        = var.nb_users
    mgmt1_ip        = local.mgmt1_ip
    home_dev        = jsonencode(local.home_dev)
    project_dev     = jsonencode(local.project_dev)
    scratch_dev     = jsonencode(local.scratch_dev)
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
        node_name             = format("mgmt%d", count.index + 1),
        sudoer_username       = var.sudoer_username,
        ssh_authorized_keys   = concat(var.public_keys, tls_private_key.ssh[*].public_key_openssh),
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
        ssh_authorized_keys   = concat(var.public_keys, tls_private_key.ssh[*].public_key_openssh),
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
        ssh_authorized_keys   = concat(var.public_keys, tls_private_key.ssh[*].public_key_openssh),
        puppetmaster_ip       = local.puppetmaster_ip,
        puppetmaster_password = random_string.puppetmaster_password.result,
      }
    )
  }
}

resource "null_resource" "deploy_hieradata" {
  count = var.instances["mgmt"]["count"] > 0 && var.instances["login"]["count"] > 0 ? 1 : 0

  connection {
    type                 = "ssh"
    bastion_host         = local.public_ip[0]
    bastion_user         = var.sudoer_username
    bastion_private_key  = try(tls_private_key.ssh[0].private_key_pem, null)
    user                 = var.sudoer_username
    host                 = local.puppetmaster_ip
    private_key          = try(tls_private_key.ssh[0].private_key_pem, null)
  }

  triggers = {
    user_data    = md5(var.hieradata)
    hieradata    = md5(data.template_file.hieradata.rendered)
    puppetmaster = local.puppetmaster_id
  }

  provisioner "file" {
    content     = data.template_file.hieradata.rendered
    destination = "terraform_data.yaml"
  }

  provisioner "file" {
    content     = var.hieradata
    destination = "user_data.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/puppetlabs/data",
      "sudo install -m 650 terraform_data.yaml user_data.yaml /etc/puppetlabs/data/",
      "sudo chgrp puppet /etc/puppetlabs/data/terraform_data.yaml /etc/puppetlabs/data/user_data.yaml &> /dev/null || true",
      "rm -f terraform_data.yaml user_data.yaml"
    ]
  }
}