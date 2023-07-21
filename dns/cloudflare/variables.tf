variable "name" {
}

variable "domain" {
}

variable "email" {
  description = "Define the email address used to issue the wildcard certificate. This address will get certificate expiration reminder."
  type    = string
  default = ""
}

variable "issue_wildcard_cert" {
  description = "Use DNS-01 challenge to generate a wildcard certificate *.name.domain_name"
  default     = false
}

variable "acme_key_pem" {
  type = string
  default = ""
}

variable "sudoer_username" {
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

variable "ssl_tags" {
  description = "Define a list of tags the instances that will receive a copy of the wildcard SSL certificate can have."
  default = ["proxy", "ssl"]
}

variable "public_instances" { }

variable "bastions" { }

variable "ssh_private_key" {
  type = string
}