locals {
  functions_extension_version = "~4"
  resource_name_prefix = "${var.business_division}-${var.project}"
}

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
  functions_extension_version = local.functions_extension_version
  
  site_config {
    minimum_tls_version = "1.2"
    ftps_state = "Disabled"
    application_insights_key = azurerm_application_insights.func_app_insights.instrumentation_key
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

resource "azurerm_service_plan" "func_service_plan" {
  for_each            = var.functions
  name                = "${local.resource_name_prefix}-${each.key}-plan"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  os_type             = "Windows"
  sku_name            = var.ap_sku_name
  lifecycle {
    ignore_changes = [
      maximum_elastic_worker_count
    ]
  }
  tags = var.tags
}

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
  access_tier = "Cool"

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

resource "azurerm_role_assignment" "app_config_data_reader_func" {
  for_each = var.functions

  scope                = var.app_config_id
  role_definition_name = "App Configuration Data Reader"
  principal_id         = azurerm_windows_function_app.new[each.key].identity[0].principal_id

}

resource "azurerm_key_vault_access_policy" "function" {
  for_each = var.functions
  key_vault_id = var.key_vault_id
  tenant_id    = var.tenant_id

  object_id = azurerm_windows_function_app.new[each.key].identity[0].principal_id

  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]
}

resource "azurerm_application_insights" "func_app_insights" {
  name                = "${local.resource_name_prefix}-app-insights"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  application_type    = "web"
  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "func_failure_alert" {
  for_each = var.functions
  name                = "${local.resource_name_prefix}-function-failure-alert"
  resource_group_name = var.resource_group.name
  scopes              = [azurerm_windows_function_app.new[each.key].id]
  description         = "Alert on function failures"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
  }

  tags = var.tags
}