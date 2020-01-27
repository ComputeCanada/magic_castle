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

variable "os_int_subnet" {
  type    = string
  default = null
}
