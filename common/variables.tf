variable "cluster_name" {}

variable "nb_nodes" {}

variable "nb_users" {}

variable "home_size" {}
variable "project_size" {}
variable "scratch_size" {}

variable "domain" {}

variable "public_key_path" {}

variable "guest_passwd" {
  default = ""
}

variable "puppet_config" {
  default = "basic"
}

variable "puppetfile_path" {
  default = ""
 }

variable "site_pp_path" {
  default = ""
 }

variable "data_path" {
  default = ""
 }

variable "email" {
  default = ""
}

locals {
  domain_name     = "${var.cluster_name}.${var.domain}"
  site_pp_path    = "${var.site_pp_path != "" ? var.site_pp_path : "${path.module}/../puppet/${var.puppet_config}/site.pp"}"
  puppetfile_path = "${var.puppetfile_path != "" ? var.puppetfile_path : "${path.module}/../puppet/${var.puppet_config}/Puppetfile"}"
  data_path       = "${var.data_path != "" ? var.data_path : "${path.module}/../puppet/${var.puppet_config}/data.yaml"}"
}
