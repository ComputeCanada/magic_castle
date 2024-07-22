variable "project" {
}

variable "zone_name" {
}

variable "name" {
}

variable "domain" {
}

variable "vhosts" {
  description = "List of vhost dns records to create as vhost.name.domain_name."
  type    = list(string)
  default = ["ipa", "jupyter", "mokey", "explore"]
}

variable "domain_tag" {
  description = "Define the tag the instances that will be pointed by the domain name A record has to have."
  default     = "login"
}

variable "vhost_tag" {
  description = "Define the tag the instances that will be pointed by the vhost A record has to have."
  default = "proxy"
}

variable "public_instances" { }
