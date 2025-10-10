variable "configuration" {
  validation {
    condition     = length(var.configuration.bastions) > 0
    error_message = "Firewall rules do not allow Terraform to SSH to at least one instance."
  }
}
variable "hieradata" {}
variable "hieradata_dir" {}
variable "eyaml_key" {}
variable "puppetfile" {}

locals {
  provision_folder = "etc_puppetlabs"
}

data "archive_file" "puppetserver_files" {
  type        = "zip"
  output_path = "${path.module}/files/${local.provision_folder}.zip"

  source {
    content  = var.configuration.terraform_data
    filename = "${local.provision_folder}/data/terraform_data.yaml"
  }

  source {
    content  = var.configuration.terraform_facts
    filename = "${local.provision_folder}/facts/terraform_facts.yaml"
  }

  source {
    content  = var.hieradata
    filename = "${local.provision_folder}/data/user_data.yaml"
  }

  dynamic "source" {
    for_each = var.hieradata_dir != "" ? fileset("${var.hieradata_dir}", "**/*.yaml") : []
    iterator = filename
    content {
      content  = file("${var.hieradata_dir}/${filename.value}")
      filename = "${local.provision_folder}/data/user_data/${filename.value}"
    }
  }

  dynamic "source" {
    for_each = var.eyaml_key != "" ? [var.eyaml_key] : []
    content {
      content  = var.eyaml_key
      filename = "${local.provision_folder}/puppet/eyaml/private_key.pkcs7.pem"
    }
  }

  dynamic "source" {
    for_each = var.puppetfile != "" ? [var.puppetfile] : []
    iterator = filename
    content {
      content  = var.puppetfile
      filename = "${local.provision_folder}/code/Puppetfile"
    }
  }
}

locals {
  bastion_host = length(var.configuration.bastions) > 0 ? var.configuration.bastions[keys(var.configuration.bastions)[0]] : null
}

resource "terraform_data" "deploy_puppetserver_files" {
  for_each = local.bastion_host != null ? var.configuration.puppetservers : {}

  connection {
    type                = "ssh"
    agent               = false
    bastion_host        = contains(local.bastion_host.tags, "public") ? local.bastion_host.public_ip : local.bastion_host.local_ip
    bastion_user        = "tf"
    bastion_private_key = var.configuration.ssh_key.private
    user                = "tf"
    host                = each.value
    private_key         = var.configuration.ssh_key.private
  }

  triggers_replace = {
    archive = data.archive_file.puppetserver_files.output_sha256
  }

  provisioner "file" {
    source      = "${path.module}/files/${local.provision_folder}.zip"
    destination = "${local.provision_folder}.zip"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo /usr/sbin/update_etc_puppetlabs.sh ${local.provision_folder}.zip",
      "rm ${local.provision_folder}.zip"
    ]
  }
}
