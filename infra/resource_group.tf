resource "azurerm_resource_group" "dev" {
  name     = local.dev_resource_group_name
  location = var.location

  tags = local.dev_tags
}

resource "azurerm_resource_group" "prod" {
  name     = local.prod_resource_group_name
  location = var.location

  tags = local.prod_tags
}

resource "azurerm_resource_group" "hub" {
  name     = local.hub_resource_group_name
  location = var.location

  tags = local.hub_tags
}
