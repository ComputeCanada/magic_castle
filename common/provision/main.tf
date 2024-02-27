variable "bastions" { }
variable "puppetservers" { }
variable "terraform_data" { }
variable "terraform_facts" { }
variable "hieradata_folder" { }
variable "hieradata" { }
variable "sudoer_username" { }
variable "tf_ssh_key" { }

data "local_file" "hieradata_yaml" {
  for_each = var.hieradata_folder != "" ? fileset("${var.hieradata_folder}", "*.yaml") : []
  filename = "${var.hieradata_folder}/${each.value}"
}

data "local_file" "hieradata_subfolder" {
  for_each = var.hieradata_folder != "" ? fileset("${var.hieradata_folder}", "{prefix,hostname}/**/*.yaml") : []
  filename = "${var.hieradata_folder}/${each.value}"
}

locals {
  connection_parameters = length(var.bastions) > 0 ? {
    bastion_host        = var.bastions[keys(var.bastions)[0]].public_ip
    bastion_user        = var.sudoer_username
    bastion_private_key = var.tf_ssh_key.private
    user                = var.sudoer_username
    private_key         = var.tf_ssh_key.private
  } : null

  hieradata_md5 = merge(
    {for value in data.local_file.hieradata_yaml: replace(value.filename, var.hieradata_folder, "") => value.content_md5},
    {for value in data.local_file.hieradata_subfolder: replace(value.filename, var.hieradata_folder, "") => value.content_md5},
  )
  triggers_hieradata_folder = {
    hieradata_yaml  = local.hieradata_md5
  }

  triggers_hieradata = {
    user_data      = md5(var.hieradata)
    terraform_data = md5(var.terraform_data)
    facts          = md5(var.terraform_facts)
  }
}

resource "terraform_data" "deploy_hieradata_folder" {
  for_each = local.connection_parameters != null && length(local.hieradata_md5) > 0 ? var.puppetservers : { }

  connection {
    type                = "ssh"
    host                = each.value
    bastion_host        = local.connection_parameters["bastion_host"]
    bastion_user        = local.connection_parameters["bastion_user"]
    bastion_private_key = local.connection_parameters["bastion_private_key"]
    user                = local.connection_parameters["user"]
    private_key         = local.connection_parameters["private_key"]
  }

  triggers_replace = local.triggers_hieradata_folder

  provisioner "file" {
    source      = "${path.cwd}/hieradata"
    destination = "hieradata"
  }

  provisioner "remote-exec" {
    inline = [
      # clean up
      "sudo rm -rf /etc/puppetlabs/data/hieradata || true",
      "sudo mkdir -p /etc/puppetlabs/data",
      # puppet user and group have been assigned the reserved UID/GID 52
      "sudo cp -r hieradata /etc/puppetlabs/data/",
      "sudo chown -R root:52 /etc/puppetlabs/data/hieradata",
      "sudo chmod -R 650 /etc/puppetlabs/data/hieradata",
      "rm -rf hieradata",
    ]
  }
}

resource "terraform_data" "deploy_hieradata" {
  for_each = local.connection_parameters != null ? var.puppetservers : { }

  connection {
    type                = "ssh"
    host                = each.value
    bastion_host        = local.connection_parameters["bastion_host"]
    bastion_user        = local.connection_parameters["bastion_user"]
    bastion_private_key = local.connection_parameters["bastion_private_key"]
    user                = local.connection_parameters["user"]
    private_key         = local.connection_parameters["private_key"]
  }

  triggers_replace = local.triggers_hieradata

  provisioner "file" {
    content     = var.terraform_data
    destination = "terraform_data.yaml"
  }

  provisioner "file" {
    content     = var.terraform_facts
    destination = "terraform_facts.yaml"
  }

  provisioner "file" {
    content     = var.hieradata
    destination = "user_data.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/puppetlabs/data /etc/puppetlabs/facts",
      # puppet user and group have been assigned the reserved UID/GID 52
      "sudo install -o root -g 52 -m 650 terraform_data.yaml user_data.yaml /etc/puppetlabs/data/",
      "sudo install -o root -g 52 -m 650 terraform_facts.yaml /etc/puppetlabs/facts/",
      "rm -f terraform_data.yaml user_data.yaml terraform_facts.yaml",
    ]
  }
}

resource "terraform_data" "update_consul" {
  for_each = local.connection_parameters != null ? var.puppetservers : { }

  connection {
    type                = "ssh"
    host                = each.value
    bastion_host        = local.connection_parameters["bastion_host"]
    bastion_user        = local.connection_parameters["bastion_user"]
    bastion_private_key = local.connection_parameters["bastion_private_key"]
    user                = local.connection_parameters["user"]
    private_key         = local.connection_parameters["private_key"]
  }

  triggers_replace = merge(
    local.triggers_hieradata,
    local.triggers_hieradata_folder,
  )

  depends_on = [
      terraform_data.deploy_hieradata,
      terraform_data.deploy_hieradata_folder,
    ]

  provisioner "remote-exec" {
    inline = [
      "[ -f /usr/local/bin/consul ] && [ -f /usr/bin/jq ] && consul event -token=$(sudo jq -r .acl.tokens.agent /etc/consul/config.json) -name=puppet $(date +%s) || true"
    ]
  }
}
