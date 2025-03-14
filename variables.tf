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