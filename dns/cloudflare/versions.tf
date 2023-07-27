
terraform {
  required_version = ">= 1.4.0"
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    acme = {
      source = "vancluever/acme"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}
