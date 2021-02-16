variable "region" {
  type        = string
  description = "Label for the AWS physical location where the cluster will be created"
}

variable "availability_zone" {
  default     = ""
  description = "Label of the datacentre inside the AWS region where the cluster will be created. If left blank, it chosen at random amongst the zones that are available."
}

locals {
  cloud_provider = "aws"
  cloud_region   = var.region
}