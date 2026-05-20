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
