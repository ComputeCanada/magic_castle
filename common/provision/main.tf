variable "bastions" { }
variable "puppetservers" { }
variable "terraform_data" { }
variable "terraform_facts" { }
variable "hieradata" { }
variable "hieradata_dir" { }
variable "tf_ssh_key" { }
variable "eyaml_key" { }
variable "puppetfile" { }

locals {
  provision_folder = "etc_puppetlabs"
}

data "archive_file" "puppetserver_files" {
  type        = "zip"
  output_path = "${path.module}/files/${local.provision_folder}.zip"

  source {
    content  = var.terraform_data
    filename = "${local.provision_folder}/data/terraform_data.yaml"
  }

  source {
    content  = var.terraform_facts
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
    for_each =  var.eyaml_key != "" ? [var.eyaml_key] : []
    content {
      content  = var.eyaml_key
      filename = "${local.provision_folder}/puppet/eyaml/private_key.pkcs7.pem"
    }
  }

  dynamic "source" {
    for_each = var.puppetfile != "" ? [var.puppetfile]: []
    iterator = filename
    content {
      content  = var.puppetfile
      filename = "${local.provision_folder}/code/Puppetfile"
    }
  }
}

resource "terraform_data" "deploy_puppetserver_files" {
  for_each = length(var.bastions) > 0  ? var.puppetservers : { }

  connection {
    type                = "ssh"
    agent               = false
    bastion_host        = var.bastions[keys(var.bastions)[0]].public_ip
    bastion_user        = "tf"
    bastion_private_key = var.tf_ssh_key.private
    user                = "tf"
    host                = each.value
    private_key         = var.tf_ssh_key.private
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
