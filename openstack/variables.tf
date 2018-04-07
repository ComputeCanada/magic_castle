variable "cluster_name" {
  default = "phoenix"
}

variable "nb_nodes" {
  default = 2
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
  default = "Test.La.Balinaise.Elle.Est.Bien.Bonne"
}

variable "compute_vcpus" {
  default = 2
}

variable "compute_ram" {
  default = 3072
}

variable "compute_disk" {
  default = 0
}
