
terraform {
  required_version = ">= 1.5.7"
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = ">= 1.50.0"
    }
  }
}
