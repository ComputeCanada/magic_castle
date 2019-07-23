variable "os_flavor_node" {
}

variable "os_flavor_login" {
}

variable "os_flavor_mgmt" {
}

variable "os_image_name" {
}

variable "os_floating_ips" {
  type    = list(string)
  default = []
}

variable "os_ext_network" {
  type    = string
  default = null
}

variable "os_int_network" {
  type    = string
  default = null
}