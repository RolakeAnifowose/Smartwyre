resource "azurerm_windows_function_app" "new" {
  for_each = var.functions

  name                        = "${local.resource_name_prefix}-${each.key}"
  location                    = var.resource_group.location
  resource_group_name         = var.resource_group.name
  service_plan_id             = azurerm_service_plan.func_service_plan[each.key].id
  storage_account_name        = azurerm_storage_account.func_storage[each.key].name
  storage_account_access_key  = azurerm_storage_account.func_storage[each.key].primary_access_key
  https_only                  = true
  client_certificate_mode     = "Required"
  functions_extension_version = "~4"
  

  site_config {
    minimum_tls_version = "1.2"
    ftps_state = "Disabled"
    app_scale_limit   = lookup(var.function_configurations[each.key], "app_scale_limit", 2)
    use_32_bit_worker = lookup(var.function_configurations[each.key], "use_32_bit_worker", false)

    application_stack {
      dotnet_version              = lookup(var.function_configurations[each.key], "dotnet_version", "v8.0")
      use_dotnet_isolated_runtime = lookup(var.function_configurations[each.key], "use_dotnet_isolated_runtime", true)
      
    }
  }

  app_settings = {
      "WEBSITE_RUN_FROM_PACKAGE" = "1"
      "environmentApplicationConfig" = var.app_config_uri
    }

  tags = var.tags

  identity {
    type = "SystemAssigned"
  }
}
