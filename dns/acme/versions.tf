terraform {
  required_version = ">= 1.2.1"
  required_providers {
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
