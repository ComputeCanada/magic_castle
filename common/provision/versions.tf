
terraform {
  required_version = ">= 1.2.1"
  required_providers {
    null = {
      source = "hashicorp/null"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}
