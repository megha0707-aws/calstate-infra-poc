resource "azurerm_log_analytics_workspace" "stage" {
  name                = "${local.stage_name_prefix}-law-logs"
  location            = azurerm_resource_group.stage.location
  resource_group_name = azurerm_resource_group.stage.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = merge(local.common_tags, {
    env = "stage"
  })
}

resource "azurerm_log_analytics_workspace" "prod" {
  name                = "${local.prod_name_prefix}-law-logs"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = merge(local.common_tags, {
    env = "prod"
  })
}
