variable "project_name" {}

variable "credentials_file" {}

variable "zone" {}

variable "zone_region" {}

variable "machine_type_mgmt" {}

variable "machine_type_login" {}

variable "machine_type_node" {}

variable "gpu_per_node" {
  type = "list"
}
