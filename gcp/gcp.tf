variable "project_name" { 
    default = "crested-return-137823"
}

variable "ssh_pub_key_file" { 
    default = "key.pub"
}

variable "ssh_user" { 
    default = "centos"
}

variable "zone" {
    default = "us-central1"
}

variable "zone_region" {
    default = "us-central1-a"
}

variable "machine_type_mgmt" {
# Minimun size to install freeipa-server
  default = "g1-small"
}

variable "machine_type_login" {
  default = "f1-micro"
}

variable "machine_type_node" {
  default = "n1-standard-1"
}

variable "gpu_per_node" {
  type    = "list"
# ["GPU card", count]
  default = ["nvidia-tesla-k80", 1]
}
