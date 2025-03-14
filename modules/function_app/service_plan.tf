resource "azurerm_service_plan" "func_service_plan" {
  for_each            = var.functions
  name                = format("planmyfunc%s", each.key)
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
