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

  required_version = ">= 1.10"
}

provider "azurerm" {
  features {
  }
}
