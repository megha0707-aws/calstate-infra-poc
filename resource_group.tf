resource "azurerm_resource_group" "stage" {
  name     = local.stage_resource_group_name
  location = var.location

  tags = merge(local.common_tags, {
    env = "stage"
  })
}

resource "azurerm_resource_group" "prod" {
  name     = local.prod_resource_group_name
  location = var.location

  tags = merge(local.common_tags, {
    env = "prod"
  })
}
