resource "random_string" "munge_key" {
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

resource "random_uuid" "consul_token" {}

locals {
  public_instances = { for key, values in var.instances : key => values if contains(values["tags"], "public") }
  puppetserver_id = try(element([for key, values in var.instances: values["id"] if contains(values["tags"], "puppet")], 0), "")
  all_tags = toset(flatten([for key, values in var.instances : values["tags"]]))

  tag_ip = { for tag in local.all_tags :
    tag => [for key, values in var.instances : values["local_ip"] if contains(values["tags"], tag)]
  }

  hieradata = templatefile("${path.module}/terraform_data.yaml",
    {
      instances = yamlencode(var.instances)
      tag_ip    = yamlencode(local.tag_ip)
      volumes   = yamlencode(var.volume_devices)
      data = {
        sudoer_username = var.sudoer_username
        freeipa_passwd  = random_string.freeipa_passwd.result
        cluster_name    = lower(var.cluster_name)
        domain_name     = var.domain_name
        guest_passwd    = var.guest_passwd != "" ? var.guest_passwd : try(random_pet.guest_passwd[0].id, "")
        consul_token    = random_uuid.consul_token.result
        munge_key       = base64sha512(random_string.munge_key.result)
        nb_users        = var.nb_users
      }
  })
  facts = {
    software_stack = var.software_stack
    cloud_provider = var.cloud_provider
    cloud_region   = var.cloud_region
  }
}

resource "null_resource" "deploy_hieradata" {
  count = contains(local.all_tags, "puppet") && contains(local.all_tags, "public") ? 1 : 0

  connection {
    type                = "ssh"
    bastion_host        = local.public_instances[keys(local.public_instances)[0]]["public_ip"]
    bastion_user        = var.sudoer_username
    bastion_private_key = var.private_ssh_key
    user                = var.sudoer_username
    host                = "puppet"
    private_key         = var.private_ssh_key
  }

  triggers = {
    user_data    = md5(var.hieradata)
    hieradata    = md5(local.hieradata)
    facts        = md5(yamlencode(local.facts))
    puppetserver = local.puppetserver_id
  }

  provisioner "file" {
    content     = local.hieradata
    destination = "terraform_data.yaml"
  }

  provisioner "file" {
    content     = yamlencode(local.facts)
    destination = "terraform_facts.yaml"
  }

  provisioner "file" {
    content     = var.hieradata
    destination = "user_data.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/puppetlabs/data",
      "sudo mkdir -p /etc/puppetlabs/facts",
      "sudo install -m 650 terraform_data.yaml user_data.yaml /etc/puppetlabs/data/",
      "sudo install -m 650 terraform_facts.yaml /etc/puppetlabs/facts/",
      # These chgrp commands do nothing if the puppet group does not yet exist
      # so these are also handled by puppet.yaml
      "sudo chgrp puppet /etc/puppetlabs/data/terraform_data.yaml /etc/puppetlabs/data/user_data.yaml &> /dev/null || true",
      "sudo chgrp puppet /etc/puppetlabs/facts/terraform_facts.yaml &> /dev/null || true",
      "rm -f terraform_data.yaml user_data.yaml terraform_facts.yaml",
    ]
  }
}