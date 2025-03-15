terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">=2.25.0, < 3.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.86.0, < 4.0.0"
    }
  }

  # backend "azurerm" {
  #   storage_account_name = "smartwyreterraformstate"
  #   container_name = "tfstate"
  #   resource_group_name = "CloudOps-Smartwyre-resource-group"
  #   key = "terraform.tfstate"
  # }

  required_version = ">= 1.10"
}

provider "azurerm" {
  features {
  }
}
