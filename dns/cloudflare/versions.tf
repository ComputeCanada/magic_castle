
terraform {
  required_version = ">= 1.2.1"
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}
