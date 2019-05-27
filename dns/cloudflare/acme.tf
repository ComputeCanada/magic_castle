provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = "${tls_private_key.private_key.private_key_pem}"
  email_address   = "felix-antoine.fortin@calculquebec.ca"
}

resource "acme_certificate" "certificate" {
  account_key_pem           = "${acme_registration.reg.account_key_pem}"
  common_name               = "${var.name}.${var.domain}"

  dns_challenge {
    provider = "cloudflare"
  }
}

resource "null_resource" "deploy_certs" {
  count = "${var.nb_login}"

  connection {
      type     = "ssh"
      user     = "centos"
      host     = "${element(var.public_ip, count.index)}"
  }

  provisioner "file" {
    content     = "${acme_certificate.certificate.private_key_pem}"
    destination = "/home/centos/privkey.pem"
  }

  provisioner "file" {
    content     = "${acme_certificate.certificate.certificate_pem}${acme_certificate.certificate.issuer_pem}"
    destination = "/home/centos/fullchain.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/letsencrypt/live/${var.name}.${var.domain}/"
      "sudo install -m 744 -o root -g root /home/centos/fullchain.pem /etc/letsencrypt/live/${var.name}.${var.domain}/",
      "sudo install -m 700 -o root -g root /home/centos/privkey.pem /etc/letsencrypt/live/${var.name}.${var.domain}/",
      "rm fullchain.pem privkey.pem",
    ]
  }
}
