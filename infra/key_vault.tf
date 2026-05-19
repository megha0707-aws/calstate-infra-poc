# Key Vaults are managed manually and referenced here so Terraform can write
# the generated PostgreSQL connection details as secrets.

data "azurerm_key_vault" "dev" {
  name                = var.dev_key_vault_name
  resource_group_name = azurerm_resource_group.dev.name
}

resource "azurerm_key_vault_secret" "dev_grouper_postgresql_admin_login" {
  name         = "grouper-postgresql-admin-login"
  value        = var.dev_grouper_postgresql.administrator_login
  key_vault_id = data.azurerm_key_vault.dev.id
  content_type = "text/plain"
}

resource "azurerm_key_vault_secret" "dev_grouper_postgresql_admin_password" {
  name         = "grouper-postgresql-admin-password"
  value        = random_password.dev_grouper_postgresql_admin.result
  key_vault_id = data.azurerm_key_vault.dev.id
  content_type = "text/plain"
}

resource "azurerm_key_vault_secret" "dev_grouper_postgresql_host" {
  name         = "grouper-postgresql-host"
  value        = azurerm_postgresql_flexible_server.dev_grouper.fqdn
  key_vault_id = data.azurerm_key_vault.dev.id
  content_type = "text/plain"
}

resource "azurerm_key_vault_secret" "dev_grouper_postgresql_database" {
  name         = "grouper-postgresql-database"
  value        = azurerm_postgresql_flexible_server_database.dev_grouper.name
  key_vault_id = data.azurerm_key_vault.dev.id
  content_type = "text/plain"
}

data "azurerm_key_vault" "prod" {
  name                = var.prod_key_vault_name
  resource_group_name = azurerm_resource_group.prod.name
}

resource "azurerm_key_vault_secret" "prod_grouper_postgresql_admin_login" {
  name         = "grouper-postgresql-admin-login"
  value        = var.prod_grouper_postgresql.administrator_login
  key_vault_id = data.azurerm_key_vault.prod.id
  content_type = "text/plain"
}

resource "azurerm_key_vault_secret" "prod_grouper_postgresql_admin_password" {
  name         = "grouper-postgresql-admin-password"
  value        = random_password.prod_grouper_postgresql_admin.result
  key_vault_id = data.azurerm_key_vault.prod.id
  content_type = "text/plain"
}

resource "azurerm_key_vault_secret" "prod_grouper_postgresql_host" {
  name         = "grouper-postgresql-host"
  value        = azurerm_postgresql_flexible_server.prod_grouper.fqdn
  key_vault_id = data.azurerm_key_vault.prod.id
  content_type = "text/plain"
}

resource "azurerm_key_vault_secret" "prod_grouper_postgresql_database" {
  name         = "grouper-postgresql-database"
  value        = azurerm_postgresql_flexible_server_database.prod_grouper.name
  key_vault_id = data.azurerm_key_vault.prod.id
  content_type = "text/plain"
}
