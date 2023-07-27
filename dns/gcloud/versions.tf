
terraform {
  required_version = ">= 1.4.0"
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    acme = {
      source = "vancluever/acme"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}
