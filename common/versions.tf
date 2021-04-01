
terraform {
  required_version = ">= 0.14"
  required_providers {
    http = {
      source = "hashicorp/http"
    }
    null = {
      source = "hashicorp/null"
    }
    random = {
      source = "hashicorp/random"
    }
    template = {
      source = "hashicorp/template"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}
