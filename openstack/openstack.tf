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
