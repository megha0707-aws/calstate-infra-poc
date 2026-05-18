# /******************************** Dev GROUPER POSTGRESQL CONFIGURATION **********************************************/

resource "azurerm_private_dns_zone" "dev_grouper_postgresql" {
  name                = "${local.dev_name_prefix}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.dev.name

  tags = merge(local.common_tags, {
    env = "dev"
  })
}

resource "azurerm_private_dns_zone_virtual_network_link" "dev_grouper_postgresql" {
  name                  = "${local.dev_name_prefix}-grouper-psql-dns-link"
  resource_group_name   = azurerm_resource_group.dev.name
  private_dns_zone_name = azurerm_private_dns_zone.dev_grouper_postgresql.name
  virtual_network_id    = azurerm_virtual_network.dev-tf-vnet.id
  registration_enabled  = false

  tags = merge(local.common_tags, {
    env = "dev"
  })
}

resource "azurerm_postgresql_flexible_server" "dev_grouper" {
  name                = local.dev_grouper_postgresql_server_name
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location

  version                       = var.dev_grouper_postgresql.version
  administrator_login           = var.dev_grouper_postgresql.administrator_login
  administrator_password        = random_password.dev_grouper_postgresql_admin.result
  sku_name                      = var.dev_grouper_postgresql.sku_name
  storage_mb                    = var.dev_grouper_postgresql.storage_mb
  backup_retention_days         = var.dev_grouper_postgresql.backup_retention_days
  geo_redundant_backup_enabled  = var.dev_grouper_postgresql.geo_redundant_backup_enabled
  delegated_subnet_id           = azurerm_subnet.dev-psql-tf-subnet.id
  private_dns_zone_id           = azurerm_private_dns_zone.dev_grouper_postgresql.id
  public_network_access_enabled = false
  zone                          = "1"

  tags = merge(local.common_tags, {
    env = "dev"
  })

  depends_on = [azurerm_private_dns_zone_virtual_network_link.dev_grouper_postgresql]
}

resource "azurerm_postgresql_flexible_server_database" "dev_grouper" {
  name      = var.dev_grouper_postgresql.database_name
  server_id = azurerm_postgresql_flexible_server.dev_grouper.id
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
  zone                          = "1"

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
