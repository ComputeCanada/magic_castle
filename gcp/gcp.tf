variable "project_name" {
}

variable "zone" {
}

variable "region" {
}

variable "gpu_per_node" {
  type = object({
    type=string,
    count=number
  })
}
