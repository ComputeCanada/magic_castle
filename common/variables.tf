variable "cluster_name" {
  type        = string
  description = "Name by which this cluster will be known as."
  validation {
    condition     = can(regex("^[a-z][0-9a-z-]{1,40}$", var.cluster_name))
    error_message = "The cluster_name value must be at most 40 lowercase alphanumeric characters and start with a letter. It can include dashes."
  }
}

variable "nb_users" {
  type        = number
  default     = 0
  description = "Number of user accounts with a common password that will be created"
}

variable "instances" {
  description = "Map that defines the parameters for each type of instance of the cluster"
  validation {
    condition = alltrue([for key, values in var.instances: can(regex("^[a-z][0-9a-z-]{1,63}$", "${key}${values.count}"))])
    error_message = "Instances' prefix plus index must be at most 63 lowercase alphanumeric characters and start with a letter. It can include dashes."
  }
  validation {
    condition     = alltrue(concat([for key, values in var.instances: [contains(keys(values), "type"), contains(keys(values), "tags")]]...))
    error_message = "Each entry in var.instances needs to have at least a type and a list of tags."
  }
  validation {
    condition = sum([for key, values in var.instances: contains(values["tags"], "proxy") ? values["count"] : 0]) < 2
    error_message = "At most one instance in var.instances can have the _proxy_ tag"
  }
  validation {
    condition = sum([for key, values in var.instances: contains(values["tags"], "login") ? 1 : 0]) < 2
    error_message = "At most one type of instances in var.instances can have the _login_ tag"
  }
}

variable "image" {
  type        = any
  description = "Name of the operating system image that will be used to create a boot disk for the instances"
}

variable "volumes" {
  description = "Map that defines the volumes to be attached to the instances"
  validation {
    condition     = length(var.volumes) > 0 ? alltrue(concat([for k_i, v_i in var.volumes: [for k_j, v_j in v_i: contains(keys(v_j), "size")]]...)) : true
    error_message = "Each volume in var.volumes needs to have at least a size attribute."
  }
}

variable "domain" {
  type        = string
  description = "String which when combined with cluster_name will formed the cluster FQDN"
  validation {
    condition     = can(regex("^[a-z][0-9a-z-.]*$", var.domain))
    error_message = "The domain value must be lowercase alphanumeric characters and start with a letter. It can include dashes and dots."
  }
}

variable "public_keys" {
  type        = list(string)
  description = "List of SSH public keys that can log in as {sudoer_username}"
}

variable "guest_passwd" {
  type        = string
  default     = ""
  description = "Guest accounts common password. If left blank, the password is randomly generated."
  validation {
    condition     = length(var.guest_passwd) == 0 || length(var.guest_passwd) >= 8
    error_message = "The guest_passwd value must at least 8 characters long or an empty string."
  }
}

variable "config_git_url" {
  type        = string
  description = "URL to the Magic Castle Puppet configuration git repo"
  validation {
    condition     = can(regex("^https://.*\\.git$", var.config_git_url))
    error_message = "The config_git_url variable must be an https url to a git repo."
  }
}

variable "config_version" {
  type        = string
  description = "Tag, branch, or commit that specifies which Puppet configuration revision is to be used"
}

variable "hieradata" {
  type        = string
  default     = "---"
  description = "String formatted as YAML defining hiera key-value pairs to be included in the puppet environment"
  validation {
    condition     = var.hieradata == "" || can(yamldecode(var.hieradata))
    error_message = "Hieradata needs to be valid YAML"
  }
}

variable "hieradata_dir" {
  type        = string
  default     = ""
  description = "Path to hieradata folder containing YAML files to be included in the puppet environment"
  validation {
    condition     = var.hieradata_dir == "" || alltrue([for filename in fileset("${var.hieradata_dir}", "**/*.yaml"): can(yamldecode(file("${var.hieradata_dir}/${filename}")))])
    error_message = "At least one YAML file in ${var.hieradata_dir} is not a valid."
  }
}

variable "sudoer_username" {
  type        = string
  default     = "centos"
  description = "Username of the administrative account"
}

variable "firewall_rules" {
  type = map(
    object({
        from_port   = number
        to_port     = number
        tag         = string
        ethertype   = optional(string, "IPv4")
        protocol    = optional(string, "tcp")
        cidr        = optional(string, "0.0.0.0/0")
      })
  )

  default = {
    ssh = { "from_port" = 22, "to_port" = 22, "tag"= "login" }
    http = { "from_port"= 80, "to_port" = 80, "tag" = "proxy" }
    https = { "from_port" = 443, "to_port" = 443, "tag" = "proxy" }
    Globus = { "from_port" = 2811, "to_port" = 2811, "cidr" = "54.237.254.192/29", "tag" = "dtn" }
    MyProxy = { "from_port" = 7512, "to_port" = 7512, "tag" = "dtn" }
    GridFTP = { "from_port" = 50000, "to_port" = 51000, "tag" = "dtn" }
  }
  description = "Map of ingress firewall rules. Rules are defined as object({from_port, to_port, tag, cidr, ethertype, protocol})."
}

variable "software_stack" {
  type        = string
  default     = "alliance"
  description = "Provider of scientific software environment"
  validation {
    condition     = var.software_stack == null || var.software_stack == "alliance" || var.software_stack == "computecanada" || var.software_stack == "eessi" || var.software_stack == ""
    error_message = "software_stack can be one of these value: \"alliance\", \"computecanada\", \"eessi\" or \"\""
  }
}

variable "pool" {
  default = []
}

variable "skip_upgrade" {
  type        = bool
  default     = false
  description = "If set to true, the packages already installed in the base image will not be upgraded on first boot."
}

variable "puppetfile" {
  type        = string
  default     = ""
  description = "Additional Puppet modules to install in the Puppetfile format."
}

variable "eyaml_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Private RSA key used to encrypt the data in the hieradata yaml fire"
  validation {
    condition     = can(regex("(|^-----BEGIN PRIVATE KEY-----\n)", var.eyaml_key))
    error_message = "Unsupported private key format"
  }
}
