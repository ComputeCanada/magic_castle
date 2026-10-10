variable "name" {
}

variable "domain" {
}

variable "vhosts" {
  description = "List of vhost dns records to create as vhost.name.domain_name."
  type        = list(string)
  default     = ["*"]
}

variable "domain_tag" {
  description = "Define the tag the instances that will be pointed by the domain name A record has to have."
  default     = "login"
}

variable "vhost_tag" {
  description = "Define the tag the instances that will be pointed by the vhost A record has to have."
  default     = "proxy"
}

variable "public_instances" {}

variable "dkim_public_key" {
  default = ""
}
variable "zone_name" {
  description = "Name of the Designate zone that holds the records. Defaults to the domain followed by a dot."
  type        = string
  default     = null
}

variable "ttl" {
  description = "Time to live in seconds of the created record sets."
  type        = number
  default     = 300
}
