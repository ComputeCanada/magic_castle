variable "os_floating_ips" {
  default = {}
}

variable "os_ext_network" {
  type    = string
  default = null
}

variable "subnet_id" {
  type    = string
  default = null
}

data "external" "keystone" {
  program = ["bash", "${path.module}/external/keystone.sh"]
}

locals {
  cloud_provider = "openstack"
  cloud_region   = data.external.keystone.result.name
}