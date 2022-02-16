variable "location" {
  type        = string
  description = "Label of the Azure location where the cluster will be created"
}

variable "azure_resource_group" {
  type        = string
  default     = ""
  description = "Name of an existing resource group that will be used when creating the computing resources. If left empty, terraform will create a new resource group."
}

variable "plan" {
  default = {
    name      = null
    product   = null
    publisher = null
  }
}

locals {
  cloud_provider = "azure"
  cloud_region   = var.location
}