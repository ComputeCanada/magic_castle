variable "storage_pool" {
    description = "Name of the storage pool used to create root disk and filesystems"
    default = "default"
}

variable "forward_proxy" {
    description = "When enabled, create a device that forward the port of the proxy container to the incus host"
    default = false
}

variable "privileged" {
    description = "When using container, set the config security.privileged to this value"
    default = true
}

variable "shared_filesystems" {
    description = "Name of filesystems that need to be created and mounted in every instance"
    default = []
}
