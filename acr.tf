resource "azurerm_container_registry" "stage" {
  name                = local.stage_acr_name
  resource_group_name = azurerm_resource_group.stage.name
  location            = azurerm_resource_group.stage.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = merge(local.common_tags, {
    env = "stage"
  })
}

resource "azurerm_container_registry" "prod" {
  name                = local.prod_acr_name
  resource_group_name = azurerm_resource_group.prod.name
  location            = azurerm_resource_group.prod.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = merge(local.common_tags, {
    env = "prod"
  })
}
