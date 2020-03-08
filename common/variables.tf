variable "cluster_name" {
}

variable "nb_users" {
  type = number
}

variable "instances" {
  type = object({
    mgmt=object({type=string, count=number}),
    login=object({type=string, count=number}),
    node=list(map(any)),
  })
}

variable "image" {
}

variable "root_disk_size" {
  default = 10
}

variable "storage" {
  type = object({
    type=string,
    home_size=number,
    project_size=number,
    scratch_size=number,
    home_vol_type=string,
    project_vol_type=string,
    scratch_vol_type=string,
  })
}

variable "domain" {
}

variable "public_keys" {
}

variable "guest_passwd" {
  default = ""
}

variable "puppetenv_git" {
  default = "https://github.com/ComputeCanada/puppet-magic_castle"
}

variable "puppetenv_rev" {
  default = "master"
}

variable hieradata {
  type = string
  default = ""
}

variable "sudoer_username" {
  default = "centos"
}

variable "firewall_rules" {
  default = [
    {
      "name"         = "SSH",
      "from_port"    = 22,
      "to_port"      = 22,
      "ip_protocol"  = "tcp",
      "cidr"         = "0.0.0.0/0"
    },
    {
      "name"         = "HTTP",
      "from_port"    = 80,
      "to_port"      = 80,
      "ip_protocol"  = "tcp",
      "cidr"         = "0.0.0.0/0"
    },
    {
      "name"         = "HTTPS",
      "from_port"    = 443,
      "to_port"      = 443,
      "ip_protocol"  = "tcp",
      "cidr"         = "0.0.0.0/0"
    },
    {
      "name"         = "Globus",
      "from_port"    = 2811,
      "to_port"      = 2811,
      "ip_protocol"  = "tcp",
      "cidr"         = "54.237.254.192/29"
    },
    {
      "name"         = "MyProxy",
      "from_port"    = 7512,
      "to_port"      = 7512,
      "ip_protocol"  = "tcp",
      "cidr"         = "0.0.0.0/0"
    },
    {
      "name"        = "GridFTP"
      "from_port"   = 50000
      "to_port"     = 51000
      "ip_protocol" = "tcp"
      "cidr"        = "0.0.0.0/0"
    }
  ]
}
