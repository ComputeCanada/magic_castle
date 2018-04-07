data "openstack_compute_flavor_v2" "node" {
  vcpus = "${var.compute_vcpus}"
  ram   = "${var.compute_ram}"
  disk  = "${var.compute_disk}"
}

variable "os_ssh_key" {
  default = "fafor10"
}

variable "os_external_network" {
  default = "VLAN3337"
}

variable "os_login_flavor_id" {
  default = "2ff7463c-dda9-4687-8b7a-80ad3303fd41"
}

variable "os_mgmt_flavor_id" {
  # p2-3gb
  default = "2ff7463c-dda9-4687-8b7a-80ad3303fd41"

  # c4-15gb-31
  # default = "9493fdd3-3100-440d-a9a1-020d93701ed2"
}

variable "os_image_id" {
  # CentOS 7
  default = "5088c906-1636-4319-9dcb-76ab92257731"
}
