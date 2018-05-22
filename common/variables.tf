variable "cluster_name" {
  default = "phoenix"
}

variable "nb_nodes" {
  default = 2
}

variable "nb_users" {
  default = 5
}

variable "shared_storage_size" {
  default = 20
}

variable "public_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtK+7I+alsG4rJvg96ycHCl9Cjugww4D+UnPXCm1qi+kwq/SHyc3dXdPt1ls47jerAj3jfWx39zFovN3eyRsxG0PyMLyl2xpeYxT9BKWVqClijYKfUBj74fFsOj9ma7rw6Y7ksNXA4zL1VVhRH7vIhgjWZZO1VH1f6GYrB6sVBsjodKYQLAF+TLPJsONYOOQe8iKxdOCob/9D5nWRgIARTNGWc4m2EQAciDoZ2Qmoy0BSFs7amhMqytmFk80Ww83K2Fa4lqn/27rMb4NZlbzYKWfmnPXefzW/oa85WmFM+al95Lwg55kXWWTgOCBj1atYizLCQwZ1KSVPcn6fQVB3Yw== felix@AtomicCaptain.local"
}

variable "domain_name" {
  default = "jupyter2.calculquebec.cloud"
}
