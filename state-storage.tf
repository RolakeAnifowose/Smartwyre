resource "azurerm_storage_account" "terraform_state" {
  name                             = var.storage_account
  location                         = var.location
  resource_group_name              = azurerm_resource_group.functions_rg.name
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  allow_nested_items_to_be_public  = false
  https_traffic_only_enabled       = true
  min_tls_version                  = "TLS1_2"
  cross_tenant_replication_enabled = true

  blob_properties {
    last_access_time_enabled = true

    delete_retention_policy {
      days = 5
    }

    container_delete_retention_policy {
      days = 5
    }

    versioning_enabled = true
  }

  tags = var.tags
}

resource "azurerm_storage_container" "terraform_state" {
  name = var.storage_container
  storage_account_name = azurerm_storage_account.terraform_state.name
  container_access_type = "private"
}