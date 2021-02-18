variable "project" {
  type        = string
  description = "Label of the unique identifier associated with the GCP project in which the resources will be created."
}

variable "region" {
  type        = string
  description = ""
}

variable "zone" {
  type        = string
  default     = ""
  description = ""
}

locals {
  cloud_provider = "gcp"
  cloud_region   = var.region
}