variable "bastions" { }
variable "puppetservers" { }
variable "terraform_data" { }
variable "terraform_facts" { }
variable "hieradata" { }
variable "sudoer_username" { }
variable "tf_ssh_key" { }
variable "eyaml_key" { }

locals {
  provision_folder = "puppetserver_etc"
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
    for_each =  var.eyaml_key != "" ? [var.eyaml_key] : []
    content {
      content  = var.eyaml_key
      filename = "${local.provision_folder}/puppet/eyaml/private_key.pkcs7.pem"
    }
  }
}

resource "terraform_data" "deploy_puppetserver_files" {
  for_each = length(var.bastions) > 0  ? var.puppetservers : { }

  connection {
    type                = "ssh"
    bastion_host        = var.bastions[keys(var.bastions)[0]].public_ip
    bastion_user        = var.sudoer_username
    bastion_private_key = var.tf_ssh_key.private
    user                = var.sudoer_username
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
      # unzip is not necessarily installed when connecting, but python is.
      "/usr/libexec/platform-python -c 'import zipfile; zipfile.ZipFile(\"${local.provision_folder}.zip\").extractall()'",
      "sudo chmod g-w,o-rwx $(find ${local.provision_folder}/ -type f)",
      "sudo chown -R root:52 ${local.provision_folder}",
      "sudo mkdir -p -m 755 /etc/puppetlabs/",
      "sudo rsync -avh --no-t ${local.provision_folder}/ /etc/puppetlabs/",
      # hiera-eyaml 3.4.0 requires a public key in the form of a X509 certificate to decrypt
      "sudo test -f ${local.provision_folder}/puppet/eyaml/private_key.pkcs7.pem && sudo openssl req -new -key /etc/puppetlabs/puppet/eyaml/private_key.pkcs7.pem -set_serial 1 -batch -out /etc/puppetlabs/puppet/eyaml/public_key.pkcs7.pem",
      "sudo rm -rf ${local.provision_folder}/ ${local.provision_folder}.zip",
      "[ -f /usr/local/bin/consul ] && [ -f /usr/bin/jq ] && consul event -token=$(sudo jq -r .acl.tokens.agent /etc/consul/config.json) -name=puppet $(date +%s) || true",
    ]
  }
}