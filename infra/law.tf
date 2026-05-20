resource "azurerm_log_analytics_workspace" "dev" {
  name                = "${local.dev_name_prefix}-law-logs"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.dev_tags
}

resource "azurerm_log_analytics_workspace" "prod" {
  name                = "${local.prod_name_prefix}-law-logs"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.prod_tags
}
