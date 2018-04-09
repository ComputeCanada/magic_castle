data "openstack_compute_flavor_v2" "mgmt" {
  name = "p2-3gb"
}

data "openstack_compute_flavor_v2" "login" {
  name = "p2-3gb"
}

data "openstack_compute_flavor_v2" "node" {
  name = "p2-3gb"
}

variable "os_ssh_key" {
  default = "fafor10"
}

variable "os_external_network" {
  default = "VLAN3337"
}

variable "os_image_id" {
  # CentOS 7
  default = "5088c906-1636-4319-9dcb-76ab92257731"
}
