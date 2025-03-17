variable "function_app_names" {
  type = list(string)
  default = [
    "pricing",
    "products",
    "rebates",
    "products-denormalizations"
  ]
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources, root and module"
  default = {
    Team          = "CloudOps"
    Environment   = "Dev"
    Project       = "Smartwyre"
    Creation-mode = "Terraform"
  }
}

variable "team" {
  description = "Team that owns infrastructure"
  type        = string
  default     = "CloudOps"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "Smartwyre"
}

variable "location" {
  description = "Azure Region for resources"
  default     = "UK South"
  type        = string
}