terraform {
  required_version = ">= 1.5.7"
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "0.3.1"
    }
  }
}
