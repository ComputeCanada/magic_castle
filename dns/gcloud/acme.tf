module "acme" {
  source              = "../acme"
  dns_provider        = "gcloud"
  dns_provider_config = { "GCE_PROJECT" = var.project }
  name                = var.name
  domain              = var.domain
  email               = var.email
  sudoer_username     = var.sudoer_username
  login_ips           = var.public_ip
}