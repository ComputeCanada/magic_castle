variable "project_name" {
}

variable "zone" {
}

variable "zone_region" {
}

variable "machine_type_mgmt" {
}

variable "machine_type_login" {
}

variable "machine_type_node" {
}

variable "gcp_image" {
}

variable "gpu_per_node" {
  type = list(string)
}

