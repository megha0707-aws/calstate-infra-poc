resource "azurerm_resource_group" "dev" {
  name     = local.dev_resource_group_name
  location = var.location

  tags = merge(local.common_tags, {
    env = "dev"
  })
}

resource "azurerm_resource_group" "prod" {
  name     = local.prod_resource_group_name
  location = var.location

  tags = merge(local.common_tags, {
    env = "prod"
  })
}
