variable "project" {
}

variable "zone_name" {
}

variable "name" {
}

variable "domain" {
}

variable "email" {
}

variable "acme_key_pem" {
  type = string
  default = ""
}

variable "sudoer_username" {
}

variable "domain_tag" {
  description = "Indicate which tag the instances that will be pointed by the domain name A record has to have."
  default     = "login"
}

variable "vhost_tag" {
  description = "Indicate which tag the instances that will be pointed by the vhost A record has to have."
  default = "proxy"
}

variable "ssl_tags" {
  description = "Indicate which tag the instances that will receive a copy of the wildcard SSL certificate has to have."
  default = ["proxy", "ssl"]
}

variable "public_instances" { }

variable "ssh_private_key" {
  type = string
}