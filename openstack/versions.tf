
terraform {
  required_version = ">= 1.2.1"
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}
