variable "location" {
  type        = string
  description = "Label of the Azure locaiton where the cluster will be created"
}

variable "azure_resource_group" {
  type        = string
  default     = ""
  description = "Name of an existing resource group that will be used when creating the computing resources. If left empty, terraform will create a new resource group."
}

variable "managed_disk_type" {
  default     = "Premium_LRS"
  description = "Typename of the instances' root disk and NFS storage disks."
}
