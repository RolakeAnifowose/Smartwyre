variable function_app_names {
    type = list(string)
    default = [
      "pricing",
      "products",
      "rebates",
      "products-denormalizations"
    ]
}

variable "tags" {
  type = map(string)
  description = "Tags applied to all resources, root and module"
  default = {
    Business-divison = "CloudOps"
    Environment = "Test"
    Project = "Smartwyre"
    Creation-mode = "Terraform"
  }
}

variable "business_division" {
    description = "Business division that owns infrastructure"
    type = string
    default = "CloudOps"
}

variable "project" {
  description = "Project name"
  type = string
  default = "Smartwyre"
}

variable "location" {
  description = "Azure Region for resources"
  default = "UK South"
}