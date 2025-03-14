resource "azurerm_storage_account" "func_storage" {
  for_each = var.functions

  name                             = lower(substr(replace(format("myfunc%s", each.key), "-", ""), 0, 24))
  location                         = var.resource_group.location
  resource_group_name              = var.resource_group.name
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  allow_nested_items_to_be_public  = false
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
  }
  tags = var.tags
}
