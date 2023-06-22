
terraform {
  required_version = ">= 1.2.1"
  required_providers {
    random = {
      source = "hashicorp/random"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}
