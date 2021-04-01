terraform {
  required_version = ">= 0.14"
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
