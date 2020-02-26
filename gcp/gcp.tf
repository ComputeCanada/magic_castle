variable "project" {
}

variable "region" {
}

variable "zone" {
  default = ""
}

variable "gpu_per_node" {
  type = object({
    type=string,
    count=number
  })
}
