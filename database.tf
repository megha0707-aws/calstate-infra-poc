# /******************************** Stage GROUPER POSTGRESQL CONFIGURATION **********************************************/

resource "azurerm_private_dns_zone" "stage_grouper_postgresql" {
  name                = "${local.stage_name_prefix}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.stage.name

  tags = merge(local.common_tags, {
    env = "stage"
  })
}

resource "azurerm_private_dns_zone_virtual_network_link" "stage_grouper_postgresql" {
  name                  = "${local.stage_name_prefix}-grouper-psql-dns-link"
  resource_group_name   = azurerm_resource_group.stage.name
  private_dns_zone_name = azurerm_private_dns_zone.stage_grouper_postgresql.name
  virtual_network_id    = azurerm_virtual_network.stage-tf-vnet.id
  registration_enabled  = false

  tags = merge(local.common_tags, {
    env = "stage"
  })
}

resource "azurerm_postgresql_flexible_server" "stage_grouper" {
  name                = local.stage_grouper_postgresql_server_name
  resource_group_name = azurerm_resource_group.stage.name
  location            = azurerm_resource_group.stage.location

  version                       = var.stage_grouper_postgresql.version
  administrator_login           = var.stage_grouper_postgresql.administrator_login
  administrator_password        = random_password.stage_grouper_postgresql_admin.result
  sku_name                      = var.stage_grouper_postgresql.sku_name
  storage_mb                    = var.stage_grouper_postgresql.storage_mb
  backup_retention_days         = var.stage_grouper_postgresql.backup_retention_days
  geo_redundant_backup_enabled  = var.stage_grouper_postgresql.geo_redundant_backup_enabled
  delegated_subnet_id           = azurerm_subnet.stage-psql-tf-subnet.id
  private_dns_zone_id           = azurerm_private_dns_zone.stage_grouper_postgresql.id
  public_network_access_enabled = false

  tags = merge(local.common_tags, {
    env = "stage"
  })

  depends_on = [azurerm_private_dns_zone_virtual_network_link.stage_grouper_postgresql]
}

resource "azurerm_postgresql_flexible_server_database" "stage_grouper" {
  name      = var.stage_grouper_postgresql.database_name
  server_id = azurerm_postgresql_flexible_server.stage_grouper.id
  charset   = "UTF8"
  collation = "en_US.utf8"

  lifecycle {
    prevent_destroy = true
  }
}

# /******************************** Prod GROUPER POSTGRESQL CONFIGURATION **********************************************/

resource "azurerm_private_dns_zone" "prod_grouper_postgresql" {
  name                = "${local.prod_name_prefix}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.prod.name

  tags = merge(local.common_tags, {
    env = "prod"
  })
}

resource "azurerm_private_dns_zone_virtual_network_link" "prod_grouper_postgresql" {
  name                  = "${local.prod_name_prefix}-grouper-psql-dns-link"
  resource_group_name   = azurerm_resource_group.prod.name
  private_dns_zone_name = azurerm_private_dns_zone.prod_grouper_postgresql.name
  virtual_network_id    = azurerm_virtual_network.prod-tf-vnet.id
  registration_enabled  = false

  tags = merge(local.common_tags, {
    env = "prod"
  })
}

resource "azurerm_postgresql_flexible_server" "prod_grouper" {
  name                = local.prod_grouper_postgresql_server_name
  resource_group_name = azurerm_resource_group.prod.name
  location            = azurerm_resource_group.prod.location

  version                       = var.prod_grouper_postgresql.version
  administrator_login           = var.prod_grouper_postgresql.administrator_login
  administrator_password        = random_password.prod_grouper_postgresql_admin.result
  sku_name                      = var.prod_grouper_postgresql.sku_name
  storage_mb                    = var.prod_grouper_postgresql.storage_mb
  backup_retention_days         = var.prod_grouper_postgresql.backup_retention_days
  geo_redundant_backup_enabled  = var.prod_grouper_postgresql.geo_redundant_backup_enabled
  delegated_subnet_id           = azurerm_subnet.prod-psql-tf-subnet.id
  private_dns_zone_id           = azurerm_private_dns_zone.prod_grouper_postgresql.id
  public_network_access_enabled = false

  tags = merge(local.common_tags, {
    env = "prod"
  })

  depends_on = [azurerm_private_dns_zone_virtual_network_link.prod_grouper_postgresql]
}

resource "azurerm_postgresql_flexible_server_database" "prod_grouper" {
  name      = var.prod_grouper_postgresql.database_name
  server_id = azurerm_postgresql_flexible_server.prod_grouper.id
  charset   = "UTF8"
  collation = "en_US.utf8"

  lifecycle {
    prevent_destroy = true
  }
}
