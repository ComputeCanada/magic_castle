
terraform {
  required_version = ">= 1.5.7"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.39.0, < 5.0.0"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}
