variable "location" {
}

variable "azure_resource_group" {
  description = "Define the name of an existing resource group that will be used when creating the computing resources. If left empty, terraform will create a new resource group."
  type = string
  default = ""
}

variable "managed_disk_type" {
  default = "Premium_LRS"
}
