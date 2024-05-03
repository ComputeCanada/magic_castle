variable "bastions" { }
variable "puppetservers" { }
variable "terraform_data" { }
variable "terraform_facts" { }
variable "hieradata" { }
variable "sudoer_username" { }
variable "tf_ssh_key" { }
variable "eyaml_key" { }

resource "terraform_data" "deploy_hieradata" {
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

  provisioner "file" {
    content     = var.eyaml_key
    destination = "private_key.pkcs7.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/puppetlabs/data /etc/puppetlabs/facts /etc/puppetlabs/puppet/eyaml",
      # puppet user and group have been assigned the reserved UID/GID 52
      "sudo install -o root -g 52 -m 640 terraform_data.yaml user_data.yaml /etc/puppetlabs/data/",
      "sudo install -o root -g 52 -m 640 terraform_facts.yaml /etc/puppetlabs/facts/",
      # install the private key if it is a non-empty file
      "test -s private_key.pkcs7.pem && sudo install -o 52 -g 52 -m 400 private_key.pkcs7.pem /etc/puppetlabs/puppet/eyaml",
      # generate the public key X509 certificate from the private key file
      # this is necessary to decrypt in hiera-eyaml 3.4.0
      "sudo openssl req -new -key private_key.pkcs7.pem  -set_serial 1 -batch -out /etc/puppetlabs/puppet/eyaml/public_key.pkcs7.pem",
      "rm -f terraform_data.yaml user_data.yaml terraform_facts.yaml private_key.pkcs7.pem",
      "[ -f /usr/local/bin/consul ] && [ -f /usr/bin/jq ] && consul event -token=$(sudo jq -r .acl.tokens.agent /etc/consul/config.json) -name=puppet $(date +%s) || true",
    ]
  }
}
