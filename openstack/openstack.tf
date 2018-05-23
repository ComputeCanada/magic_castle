variable "os_flavor_node" {}
variable "os_flavor_login" {}
variable "os_flavor_mgmt" {}

variable "os_external_network" {
  default = "VLAN3337"
}

variable "os_image_id" {
  # CentOS 7
  default = "5088c906-1636-4319-9dcb-76ab92257731"
}
