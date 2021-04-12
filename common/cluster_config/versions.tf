
terraform {
  required_version = ">= 0.14"
  required_providers {
    null = {
      source = "hashicorp/null"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}
