variable "path_ssh_public_key" {
  default = "./key.pub"
}

variable "ssh_user" {
  default = "centos"
}

variable "location" {
  default = "eastus"
}

variable "vm_size_mgmt" {
  default = "Standard_DS1_v2"
}

variable "vm_size_login" {
  default = "Standard_DS1_v2"
}

variable "vm_size_node" {
  default = "Standard_DS1_v2"
}
