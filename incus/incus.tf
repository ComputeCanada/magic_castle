variable "storage_pool" {
    default = "default"
}

variable "forward_proxy" {
    default = false
}

variable "privileged" {
    description = "When using container, set the config security.privileged to this value"
    default = true
}

variable "shared_filesystems" {
    default = []
}
