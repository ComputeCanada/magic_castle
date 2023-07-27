
terraform {
  required_version = ">= 1.4.0"
  required_providers {
    random = {
      source = "hashicorp/random"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}
