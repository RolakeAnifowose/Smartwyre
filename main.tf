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

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
    key_permissions    = ["Get", "List", "Update", "Create", "Import", "Delete", "Backup", "Recover", "Backup", "Restore"]
  }

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  tags = var.tags
}

resource "azurerm_user_assigned_identity" "identity" {
  location            = var.location
  name                = "${local.resource_name_prefix}-user-assigned-identity"
  resource_group_name = azurerm_resource_group.functions_rg.name
}

resource "azurerm_key_vault_key" "key" {
  name         = "${local.resource_name_prefix}-vault-key"
  key_vault_id = azurerm_key_vault.functions_kv.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
}

resource "azurerm_app_configuration" "functions_appcfg" {
  name                = "${local.resource_name_prefix}-appcfg"
  resource_group_name = azurerm_resource_group.functions_rg.name
  location            = var.location
  tags                = var.tags
}

module "function_app" {
  source = "github.com/RolakeAnifowose/smartwyre-function-module?ref=v0.0.7"

  functions      = toset(var.function_app_names)
  resource_group = azurerm_resource_group.functions_rg
  app_config_uri = azurerm_app_configuration.functions_appcfg.endpoint
  app_config_id  = azurerm_app_configuration.functions_appcfg.id
  tenant_id      = data.azurerm_client_config.current.tenant_id
  key_vault_id   = azurerm_key_vault.functions_kv.id
  identity_id    = azurerm_user_assigned_identity.identity.id
  key_id         = azurerm_key_vault_key.key.id

  function_configurations = {
    "pricing" = {
      app_scale_limit             = 2,
      dotnet_version              = "v6.0",
      use_32_bit_worker           = false,
      use_dotnet_isolated_runtime = true
    }
    "products" = {
      app_scale_limit             = 3,
      dotnet_version              = "v6.0",
      use_32_bit_worker           = false,
      use_dotnet_isolated_runtime = true
    }
    "rebates" = {
      app_scale_limit             = 4,
      dotnet_version              = "v8.0",
      use_32_bit_worker           = false,
      use_dotnet_isolated_runtime = true
    }
    "products-denormalizations" = {
      app_scale_limit             = 3,
      dotnet_version              = "v8.0",
      use_32_bit_worker           = false,
      use_dotnet_isolated_runtime = true
    }
  }
  tags                 = var.tags
  team                 = var.team
  project              = var.project
  resource_name_prefix = local.resource_name_prefix
}
