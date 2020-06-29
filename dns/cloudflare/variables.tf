variable "name" {
}

variable "domain" {
}

variable "public_ip" {
  type = list(string)
}

variable "rsa_public_key" {
}

variable "email" {
}

variable "sudoer_username" {
}

variable "login_ids" {
  type = list(string)
}

variable "ssh_private_key" {
  type = string
}