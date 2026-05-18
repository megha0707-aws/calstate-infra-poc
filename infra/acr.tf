resource "azurerm_container_registry" "dev" {
  name                = local.dev_acr_name
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = merge(local.common_tags, {
    env = "dev"
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
