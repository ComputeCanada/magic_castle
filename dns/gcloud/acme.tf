provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "email" {
}

variable "sudoer_username" {
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = var.email
}

resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = "${var.name}.${var.domain}"
  subject_alternative_names = ["*.${var.name}.${var.domain}"]

  dns_challenge {
    provider = "gcloud"
  }
}

resource "null_resource" "deploy_certs" {
  count = length(var.public_ip)

  connection {
    type = "ssh"
    user = var.sudoer_username
    host = element(var.public_ip, count.index)
  }

  provisioner "file" {
    content     = acme_certificate.certificate.private_key_pem
    destination = "privkey.pem"
  }

  provisioner "file" {
    content     = "${acme_certificate.certificate.certificate_pem}${acme_certificate.certificate.issuer_pem}"
    destination = "fullchain.pem"
  }

  provisioner "file" {
    content     = acme_certificate.certificate.certificate_pem
    destination = "cert.pem"
  }

  provisioner "file" {
    content     = acme_certificate.certificate.issuer_pem
    destination = "chain.pem"
  }

  provisioner "file" {
    destination = "renewal.conf"
    content     = <<EOF
version = 0.34.2
archive_dir = /etc/letsencrypt/archive/${var.name}.${var.domain}
cert = /etc/letsencrypt/live/${var.name}.${var.domain}/cert.pem
privkey = /etc/letsencrypt/live/${var.name}.${var.domain}/privkey.pem
chain = /etc/letsencrypt/live/${var.name}.${var.domain}/chain.pem
fullchain = /etc/letsencrypt/live/${var.name}.${var.domain}/fullchain.pem

[renewalparams]
authenticator = nginx
installer = nginx
account = ${basename(acme_certificate.certificate.id)}
server = https://acme-v02.api.letsencrypt.org/directory

EOF

  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/letsencrypt/{archive,live}/${var.name}.${var.domain}/",
      "sudo mkdir -p /etc/letsencrypt/renewal/",
      "sudo install -m 644 -o root -g root fullchain.pem /etc/letsencrypt/archive/${var.name}.${var.domain}/fullchain1.pem",
      "sudo install -m 644 -o root -g root chain.pem /etc/letsencrypt/archive/${var.name}.${var.domain}/chain1.pem",
      "sudo install -m 644 -o root -g root cert.pem /etc/letsencrypt/archive/${var.name}.${var.domain}/cert1.pem",
      "sudo install -m 600 -o root -g root privkey.pem /etc/letsencrypt/archive/${var.name}.${var.domain}/privkey1.pem",
      "sudo install -m 644 -o root -g root renewal.conf /etc/letsencrypt/renewal/${var.name}.${var.domain}.conf",
      "sudo ln -sf /etc/letsencrypt/archive/${var.name}.${var.domain}/privkey1.pem /etc/letsencrypt/live/${var.name}.${var.domain}/privkey.pem",
      "sudo ln -sf /etc/letsencrypt/archive/${var.name}.${var.domain}/fullchain1.pem /etc/letsencrypt/live/${var.name}.${var.domain}/fullchain.pem",
      "sudo ln -sf /etc/letsencrypt/archive/${var.name}.${var.domain}/cert1.pem /etc/letsencrypt/live/${var.name}.${var.domain}/cert.pem",
      "sudo ln -sf /etc/letsencrypt/archive/${var.name}.${var.domain}/chain1.pem /etc/letsencrypt/live/${var.name}.${var.domain}/chain.pem",
      "rm cert.pem chain.pem fullchain.pem privkey.pem renewal.conf",
    ]
  }
}
