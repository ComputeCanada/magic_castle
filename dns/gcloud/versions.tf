
terraform {
  required_version = ">= 1.4.0"
  required_providers {
    google = {
      source = "hashicorp/google"
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
