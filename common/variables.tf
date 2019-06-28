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

variable "firewall_rules" {
  default = [
    {
      "from_port"    = 22,
      "to_port"      = 22,
      "ip_protocol"  = "tcp",
      "cidr"         = "0.0.0.0/0"
    },
    {
      "from_port"    = 80,
      "to_port"      = 80,
      "ip_protocol"  = "tcp",
      "cidr"         = "0.0.0.0/0"
    },
    {
      "from_port"    = 443,
      "to_port"      = 443,
      "ip_protocol"  = "tcp",
      "cidr"         = "0.0.0.0/0"
    },
    {
      "from_port"    = 2811,
      "to_port"      = 2811,
      "ip_protocol"  = "tcp",
      "cidr"         = "54.237.254.192/29"
    },
    {
      "from_port"    = 7512,
      "to_port"      = 7512,
      "ip_protocol"  = "tcp",
      "cidr"         = "54.237.254.192/29"
    },
    {
      "from_port"   = 50000
      "to_port"     = 51000
      "ip_protocol" = "tcp"
      "cidr"        = "0.0.0.0/0"
    }
  ]
}