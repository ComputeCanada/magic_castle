
terraform {
  required_version = ">= 1.4.0"
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    acme = {
      source = "vancluever/acme"
    }
    null = {
      source = "hashicorp/null"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}
