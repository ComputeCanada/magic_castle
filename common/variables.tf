variable "cluster_name" {
  type        = string
  description = "Name by which this cluster will be known as."
}

variable "nb_users" {
  type        = number
  description = "Number of user accounts with a common password that will be created"
}

variable "instances" {
  type = object({
    mgmt=object({type=string, count=number}),
    login=object({type=string, count=number}),
    node=list(map(any)),
  })
  description = "Map that defines the parameters for each type of instance of the cluster"
}

variable "image" {
  type        = any
  description = "Name of the operating system image that will be used to create a boot disk for the instances"
}

variable "root_disk_size" {
  type        = number
  default     = 10
  description = "Size of the instances root disk in GB"
}

variable "storage" {
  type = object({
    type=string,
    home_size=number,
    project_size=number,
    scratch_size=number
  })
  description = "Map that defines the storage parameters"
}

variable "domain" {
  type        = string
  description = "String which when combined with cluster_name will formed the cluster FQDN"
}

variable "public_keys" {
  type        = list
  description = "List of SSH public keys that can log in as {sudoer_username}"
}

variable "guest_passwd" {
  type        = string
  default     = ""
  description = "Guest accounts common password. If left blank, the password is randomly generated."
}

variable "puppetenv_git" {
  type        = string
  default     = "https://github.com/ComputeCanada/puppet-magic_castle"
  description = "URL to the Magic Castle puppet environment git repo"
}

variable "puppetenv_rev" {
  type        = string
  default     = "master"
  description = "Define which commit of the puppet environment repo will be used. Can be any reference that would be accepted by the git checkout"
}

variable hieradata {
  type        = string
  default     = "---"
  description = "String formatted as YAML defining hiera key-value pairs to be included in the puppet environment"
}

variable "sudoer_username" {
  type        = string
  default     = "centos"
  description = "Username of the administrative account"
}

variable "firewall_rules" {
  type    = list(
    object({
      name        = string
      from_port   = number
      to_port     = number
      ip_protocol = string
      cidr        = string
    })
  )
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
      "name"        = "GridFTP",
      "from_port"   = 50000,
      "to_port"     = 51000,
      "ip_protocol" = "tcp",
      "cidr"        = "0.0.0.0/0"
    }
  ]
  description = "List of login external firewall rules defined as map of 5 values name, from_port, to_port, ip_protocol and cidr"
}

variable "generate_ssh_key" {
  type        = bool
  default     = false
  description = "If set to true, Terraform will generate an ssh keypair to connect to the cluster. Default: false"
}