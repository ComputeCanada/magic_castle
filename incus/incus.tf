variable "storage_pool" {
  description = "Name of the storage pool used to create root disk and filesystems"
  default     = "default"
}

variable "forward_proxy" {
  description = "When enabled, create a device that forward the port of the proxy container to the incus host"
  default     = false
}

variable "privileged" {
  description = "When using container, set the config security.privileged to this value"
  default     = true
}

variable "shared_filesystems" {
  description = "Name of filesystems that need to be created and mounted in every instance"
  default     = []
}

variable "ovn_subnet" {
  default     = "10.0.0.1/8"
  type        = string
  description = "Subnet used by OVN network. We assume that the subnet is /8"
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/8$", var.ovn_subnet))
    error_message = "The subnet_cidr must be a valid IPv4 CIDR with /8 mask (e.g., 10.0.0.0/8)."
  }
}

variable "ovn_uplink_network" {
  default     = "UPLINK"
  type        = string
  description = "Uplink bridge network used by OVN. `ipv4.ovn.ranges` must be set"
}

variable "network_type" {
  description = "Type of network to use (bridge or ovn)"
  type        = string
  default     = "bridge"

  validation {
    condition     = contains(["bridge", "ovn"], var.network_type)
    error_message = "network_type must be either 'bridge' or 'ovn'."
  }
}
