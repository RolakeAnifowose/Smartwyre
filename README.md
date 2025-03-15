# Terraform Refactoring Summary

## Overview
This document outlines the changes made to improve the Terraform configuration for deploying Azure Function Apps. 

## Key Changes and Rationale

### Updated Storage Account Naming
- **Change**: Used the `replace` function to ensure compliance with terraform's storage account naming rules by replacing the `-` in the final storage account with a ``.
- **Code**: name = lower(substr(replace(format("myfunc%s", each.key), "-", ""), 0, 24))
- **Rationale**: Azure storage accounts do not allow hyphens and must not exceed 24 characters.

### Dynamic Function App Configuration
- **Change**: Added a `function_configurations` variable to allow dynamic configuration of function apps (e.g., `app_scale_limit`, `dotnet_version`).
- **Rationale**: The previous code had rigid configurations. Using a map allows flexibility for different configurations of function apps, making it easier to scale and customize them as needed.

### Variables for Reusability
- **Change**: Introduced variables in modules and root folders to make the code configurable.
- **Rationale**: Variables make it easier to make changes and adhere to DRY principles.

### Uniform Naming Convention
- **Change**: Added a resource name prefix to resource names containing the business division and project, ensuring uniformity across resources.
- **Addition**: name = "${local.resource_name_prefix}-${each.key}-plan"
- ```hcl
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
  ```
- **Rationale**: Uniform naming makes it easier to keep track of related resources.

### Tagging for Consistency
- **Change**: Introduced a global `tags` variable to ensure all resources are tagged consistently.
```hcl
  variable "tags" {
    type        = map(string)
    description = "Tags applied to all resources, root and module"
    default = {
      Business-divison = "CloudOps"
      Environment      = "Test"
      Project          = "Smartwyre"
      Creation-mode    = "Terraform"
    }
  }
```
- **Rationale**: Tagging is essential for resource management, cost tracking, and compliance. Created global tags containing business division, environment, project and creation mode.

### Enhanced Security for Azure Key Vault
- **Change**: Implemented network ACLs for the Azure Key Vault with `bypass = "AzureServices"` and `default_action = "Deny"`.
- **Rationale**: This enhances security by ensuring that only Azure services can access the key vault, denying all external traffic and reducing the attack surface.


### Improved Access Control for Key Vault
- **Change**: Enabled **soft delete retention** and **purge protection** in the key vault configuration to retain deleted secrets for 7 days and prevent permanent deletion.
- **Rationale**: These features ensure that secrets are not accidentally deleted and provide an additional layer of protection and recovery, which aligns with Azure's security best practices.

### Azure Remote Backend for State Storage
- **Change**: Configured an Azure Storage Account as the remote backend for Terraform state files.
  - **`backend.tf`** example:
    ```hcl
    terraform {
      backend "azurerm" {
        storage_account_name = "smartwyreterraformstate"
        container_name       = "tfstate"
        resource_group_name = "CloudOps-Smartwyre-resource-group"
        key                  = "terraform.tfstate"
      }
    }
    ```
- **Rationale**: Using a remote backend like Azure Storage for state management enables centralized and secure state storage. It improves team collaboration by ensuring that state files are not lost, and it supports locking to avoid state corruption during concurrent operations.

### Versioning for Terraform State Blob
- **Change**: Enabled versioning on the blob storage container to store and manage different versions of the state file.
  - **Addition**:
    ```hcl
    resource "azurerm_storage_account" "terraform_state" {
      name                     = var.storage_account
      account_tier             = "Standard"
      account_replication_type = "LRS"
      blob_properties {
	      versioning_enabled = true
      }
    }

    resource "azurerm_storage_container" "terraform_state" {
      name                  = "tfstate"
      storage_account_name  = azurerm_storage_account.terraform_state.name
      container_access_type = "private"
    }
    ```
    Enable versioning directly on the container using Azure Portal or via ARM templates.
- **Rationale**: Versioning allows easy recovery of previous versions of the state file in case of mistakes or failures, providing an additional layer of safety.

### Creating a Deployment Pipeline for Azure
- **Change**: Created a CI/CD pipeline using GitHub Actions to automate the deployment process.
  - **GitHub Actions Workflow Example**:
    ```yaml
    name: Terraform CI/CD Pipeline for Smartwyre Platform Engineer Assessment

    on:
      push:
        branches:
          - develop

    env:
      ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
      ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

    permissions:
      contents: read
      pages: write
      id-token: write

    jobs:
      terraform:
        runs-on: ubuntu-latest

        steps:
        - name: Checkout code
          uses: actions/checkout@v2

        - name: Setup Terraform
          uses: hashicorp/setup-terraform@v1
          with:
            terraform_version: 1.10.3

        - name: Azure Login
          uses: azure/login@v1
          with:
            creds: ${{ secrets.AZURE_CREDENTIALS }}
        
        - name: Initialise
          run: terraform init

        - name: Validate
          run: terraform validate

        - name: Plan
          run: terraform plan

        - name: Apply
          run: terraform apply -auto-approve
    ```
- **Rationale**: Automating deployment with a pipeline ensures consistent and repeatable infrastructure deployment. This approach eliminates manual errors and reduces the time taken to push changes to production.

### Adding Monitoring with Azure Monitor

- **Change**: Integrated Azure Application Insights and Azure Monitor Metric Alerts for monitoring function app performance and failures.
  - **Azure Application Insights** for tracking application health and usage.
  - **Azure Monitor Metric Alerts** for setting up custom alerts based on function failures.

   Addition:

  ```hcl
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
- **Rationale**: Monitoring helps ensure that function apps are performing as expected and provides insights into usage patterns, errors, and failures. 

## Reusability Consideration
**Git-based Module Source**: taking reusability into consideration, I created the function module as a reusable module and pushed it to a GitHub repository, versioning it and then using it as my source.
 ```hcl
module  "function_app" {
  source = "github.com/RolakeAnifowose/smartwyre-function-module?ref=v0.0.1"
  functions = toset(var.function_app_names)
  resource_group = azurerm_resource_group.functions_rg
  app_config_uri = azurerm_app_configuration.functions_appcfg.endpoint
  app_config_id = azurerm_app_configuration.functions_appcfg.id
  tenant_id = data.azurerm_client_config.current.tenant_id
  key_vault_id = azurerm_key_vault.functions_kv.id
}
```
**GitHub Repository for Function module:** https://github.com/RolakeAnifowose/smartwyre-function-module