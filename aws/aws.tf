variable "region" {
  type        = string
  description = "Label for the AWS physical location where the cluster will be created"
}

variable "availability_zone" {
  default     = ""
  description = "Label of the datacentre inside the AWS region where the cluster will be created. If left blank, it chosen at random amongst the zones that are available."
}

variable "default_tags" {
  default     = {}
  description = "AWS provider default tags. Applied to all resources created by Magic Castle."
  type        = map(string)
}

locals {
  cloud_provider = "aws"
  cloud_region   = var.region
}

variable "subnet_id" {
  type        = string
  default     = null
  description = "UUID of the cluster's subnet. If left blank, a new VPC and a new subnet are created."
}