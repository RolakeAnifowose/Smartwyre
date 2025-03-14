# resource "azurerm_log_analytics_workspace" "log_workspace" {
#   name                = "${local.resource_name_prefix}-logs"
#   location            = var.resource_group.location
#   resource_group_name = var.resource_group.name
#   sku                 = "PerGB2018"
# }

resource "azurerm_application_insights" "func_app_insights" {
  name                = "${local.resource_name_prefix}-app-insights"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  application_type    = "web"
  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "func_failure_alert" {
  for_each = var.functions
  name                = "${local.resource_name_prefix}function-failure-alert"
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

  # action {
  #   action_group_id = azurerm_monitor_action_group.notification.id
  # }
}
