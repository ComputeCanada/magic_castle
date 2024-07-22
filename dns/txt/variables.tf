variable "name" {
}

variable "domain" {
}

variable "public_instances" { }

variable "domain_tag" {
  description = "Indicate which tag the instances that will be pointed by the domain name A record has to have."
  default     = "login"
}

variable "vhost_tag" {
  description = "Indicate which tag the instances that will be pointed by the vhost A record has to have."
  default = "proxy"
}

variable "vhosts" {
  description = "List of vhost records A to create."
  type    = list(string)
  default = ["ipa", "jupyter", "mokey", "explore"]
}
