variable "forward_proxy" {
    default = false
}

variable "privileged" {
    description = "When using container, set the config security.privileged to this value"
    default = true
}
