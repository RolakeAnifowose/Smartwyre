data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "functions_rg" {
  name     = "${local.resource_name_prefix}-resource-group"
  location = var.location
  tags     = var.tags
}

resource "azurerm_key_vault" "functions_kv" {
  name                       = "${local.resource_name_prefix}-vault"
  resource_group_name        = azurerm_resource_group.functions_rg.name
  location                   = var.location
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  network_acls {
    bypass = "AzureServices"
    default_action = "Deny"
  }

  tags = var.tags
}

resource "azurerm_app_configuration" "functions_appcfg" {
  name                = "${local.resource_name_prefix}-appconfig-morolake"
  resource_group_name = azurerm_resource_group.functions_rg.name
  location            = var.location
  tags                = var.tags
}

module "function_app" {
  source = "github.com/RolakeAnifowose/smartwyre-function-module?ref=v0.0.16"

  functions      = toset(var.function_app_names)
  resource_group = azurerm_resource_group.functions_rg
  app_config_uri = azurerm_app_configuration.functions_appcfg.endpoint
  app_config_id  = azurerm_app_configuration.functions_appcfg.id
  tenant_id      = data.azurerm_client_config.current.tenant_id
  key_vault_id   = azurerm_key_vault.functions_kv.id

  function_configurations = {
    "pricing" = {
      app_scale_limit             = 2,
      dotnet_version              = "v6.0",
      use_32_bit_worker           = false,
      use_dotnet_isolated_runtime = true,
      minimum_tls_version         = "1.2"
    }
    "products" = {
      app_scale_limit             = 3,
      dotnet_version              = "v6.0",
      use_32_bit_worker           = false,
      use_dotnet_isolated_runtime = true,
      minimum_tls_version         = "1.2"
    }
    "rebates" = {
      app_scale_limit             = 4,
      dotnet_version              = "v8.0",
      use_32_bit_worker           = false,
      use_dotnet_isolated_runtime = true,
      minimum_tls_version         = "1.2"
    }
    "products-denormalizations" = {
      app_scale_limit             = 3,
      dotnet_version              = "v8.0",
      use_32_bit_worker           = false,
      use_dotnet_isolated_runtime = true,
      minimum_tls_version         = "1.2"
    }
  }
  tags                 = var.tags
  team                 = var.team
  project              = var.project
  resource_name_prefix = local.resource_name_prefix
}
