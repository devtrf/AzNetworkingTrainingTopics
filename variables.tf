variable "resource_group_location" {
  default     = "southcentralus"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  default     = "rg"
  description = "Prefix for the RSG to add to the randomize"
}