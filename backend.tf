terraform {
    backend "azurerm" {
    storage_account_name = "smartwyreterraformstate"
    container_name       = "tfstate"
    resource_group_name  = "CloudOps-Smartwyre-terraform-backend-group"
    key                  = "terraform.tfstate"
  }
}