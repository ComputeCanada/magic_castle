variable "path_ssh_public_key" {
  default = "./key.pub"
}

variable "ssh_user" {
  default = "centos"
}

variable "location" {
  default = "eastus"
}

data "vm_size" "mgmt" {
  name = "Standard_DS1_v2"
}

data "vm_size" "login" {
  name = "Standard_DS1_v2"
}

data "vm_size" "node" {
  name = "Standard_DS1_v2"
}
