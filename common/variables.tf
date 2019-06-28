variable "cluster_name" {
}

variable "nb_mgmt" {
  default = 1
}

variable "nb_login" {
  default = 1
}

variable "nb_nodes" {
}

variable "nb_users" {
}

variable "home_size" {
}

variable "project_size" {
}

variable "scratch_size" {
}

variable "domain" {
}

variable "public_key_path" {
}

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

variable "sudoer_username" {
  default = "centos"
}
