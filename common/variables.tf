variable "cluster_name" {}

variable "nb_nodes" {}

variable "nb_users" {}

variable "shared_storage_size" {}

variable "domain" {}

variable "public_key_path" {}

variable "globus_user" {}

variable "globus_password" {}

locals {
  domain_name = "${var.cluster_name}.${var.domain}"
}