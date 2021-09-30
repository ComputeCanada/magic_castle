
variable "sudoer_username" {}

variable "public_instances" {}

variable "ssh_private_key" {
  type = string
}

resource "tls_private_key" "dkim" {
  algorithm = "RSA"
}

resource "null_resource" "deploy_certs" {
  for_each = var.public_instances

  triggers = {
    instance_id    = each.value["id"]
    certificate_id = tls_private_key.dkim.id
  }

  connection {
    type        = "ssh"
    user        = var.sudoer_username
    host        = each.value["public_ip"]
    host_key    = each.value["hostkeys"]["rsa"]
    private_key = var.ssh_private_key
  }

  provisioner "file" {
    content     = tls_private_key.dkim.private_key_pem
    destination = "default.private"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/opendkim/keys",
      "sudo install -m 600 -o root -g root default.private /etc/opendkim/keys/",
      "rm default.private",
    ]
  }
}

data "external" "rsa2der" {
  program = ["python", "${path.module}/rsa2der.py"]
  query = {
    private_key = tls_private_key.dkim.private_key_pem
  }
}

output "public_key" {
    value = data.external.rsa2der.result["public_key"]
}