variable "resource_group_name_prefix" {
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "vm_name" {
  description = "Name of the VM."
  type        = list(string)
  default     = ["VMNode1", "VMNode2"]
}

variable "resource_group_location" {
  default     = "eastasia"
  description = "Location of the resource group."
}
