variable "bastions" { }
variable "puppetservers" { }
variable "terraform_data" { }
variable "terraform_facts" { }
variable "hieradata" { }
variable "sudoer_username" { }
variable "tf_ssh_key" { }

resource "null_resource" "deploy_hieradata" {
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

  triggers = {
    user_data      = md5(var.hieradata)
    terraform_data = md5(var.terraform_data)
    facts          = md5(var.terraform_facts)
  }

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
      "[ -f /usr/local/bin/consul ] && [ -f /usr/bin/jq ] && consul event -token=$(sudo jq -r .acl.tokens.agent /etc/consul/config.json) -name=puppet $(date +%s) || true",
    ]
  }
}
