variable "nb_nodes" {
  default = 5
}

variable "nb_users" {
  default = 20
}

variable "shared_storage_size" {
  default = 50
}

variable "admin_passwd" {
  default = "changeme"
}

variable "guest_passwd" {
  default = "UQTR20180329"
}

variable "compute_vcpus" {
  default = 2
}

variable "compute_ram" {
  default = 7680
}

variable "compute_disk" {
  default = 20
}

variable "os_flavor_id" {
  default = "2ff7463c-dda9-4687-8b7a-80ad3303fd41"
}

variable "os_login_flavor_id" {
  # p2-3gb
  # default = "2ff7463c-dda9-4687-8b7a-80ad3303fd41"
  # c4-15gb-31
  default = "9493fdd3-3100-440d-a9a1-020d93701ed2"
}

variable "os_image_id" {
  # CentOS 7
  default = "5088c906-1636-4319-9dcb-76ab92257731"
}
