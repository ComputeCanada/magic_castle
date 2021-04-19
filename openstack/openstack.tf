variable "os_floating_ips" {
  default = {}
}

variable "os_ext_network" {
  type    = string
  default = null
}

variable "os_int_network" {
  type    = string
  default = null
}

variable "os_int_subnet" {
  type    = string
  default = null
}

data "external" "keystone" {
  program = ["python", "${path.module}/external/keystone.py"]
}

locals {
  cloud_provider = "openstack"
  cloud_region   = data.external.keystone.result.name
}