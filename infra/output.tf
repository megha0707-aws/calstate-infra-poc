output "configuration_summary" {
  description = "Summary of the dedicated Grouper AKS infrastructure template."
  value = {
    dev = {
      region         = azurerm_resource_group.dev.location
      resource_group = azurerm_resource_group.dev.name
      aks = {
        name = azurerm_kubernetes_cluster.dev_aks_cluster.name
        id   = azurerm_kubernetes_cluster.dev_aks_cluster.id
      }
      virtual_network = {
        name = azurerm_virtual_network.dev-tf-vnet.name
        id   = azurerm_virtual_network.dev-tf-vnet.id
      }
      subnets = {
        app_gateway = azurerm_subnet.dev-appgw-tf-subnet.id
        postgresql  = azurerm_subnet.dev-psql-tf-subnet.id
        aks         = azurerm_subnet.dev-aks-tf-subnet.id
      }
      container_registry = {
        name         = azurerm_container_registry.dev.name
        login_server = azurerm_container_registry.dev.login_server
      }
      log_analytics = {
        name = azurerm_log_analytics_workspace.dev.name
        id   = azurerm_log_analytics_workspace.dev.id
      }
      key_vault = {
        name = data.azurerm_key_vault.dev.name
        id   = data.azurerm_key_vault.dev.id
        uri  = data.azurerm_key_vault.dev.vault_uri
        postgresql_secret_names = {
          admin_login    = azurerm_key_vault_secret.dev_grouper_postgresql_admin_login.name
          admin_password = azurerm_key_vault_secret.dev_grouper_postgresql_admin_password.name
          host           = azurerm_key_vault_secret.dev_grouper_postgresql_host.name
          database       = azurerm_key_vault_secret.dev_grouper_postgresql_database.name
        }
      }
      grouper_postgresql = {
        name             = azurerm_postgresql_flexible_server.dev_grouper.name
        id               = azurerm_postgresql_flexible_server.dev_grouper.id
        fqdn             = azurerm_postgresql_flexible_server.dev_grouper.fqdn
        database_name    = azurerm_postgresql_flexible_server_database.dev_grouper.name
        private_dns_zone = azurerm_private_dns_zone.dev_grouper_postgresql.name
      }
      node_pools = {
        default = var.dev_default_node_pool.name
      }
    }

    prod = {
      region         = azurerm_resource_group.prod.location
      resource_group = azurerm_resource_group.prod.name
      aks = {
        name = azurerm_kubernetes_cluster.prod_aks_cluster.name
        id   = azurerm_kubernetes_cluster.prod_aks_cluster.id
      }
      virtual_network = {
        name = azurerm_virtual_network.prod-tf-vnet.name
        id   = azurerm_virtual_network.prod-tf-vnet.id
      }
      subnets = {
        app_gateway = azurerm_subnet.prod-appgw-tf-subnet.id
        postgresql  = azurerm_subnet.prod-psql-tf-subnet.id
        aks         = azurerm_subnet.prod-aks-tf-subnet.id
      }
      container_registry = {
        name         = azurerm_container_registry.prod.name
        login_server = azurerm_container_registry.prod.login_server
      }
      log_analytics = {
        name = azurerm_log_analytics_workspace.prod.name
        id   = azurerm_log_analytics_workspace.prod.id
      }
      key_vault = {
        name = data.azurerm_key_vault.prod.name
        id   = data.azurerm_key_vault.prod.id
        uri  = data.azurerm_key_vault.prod.vault_uri
        postgresql_secret_names = {
          admin_login    = azurerm_key_vault_secret.prod_grouper_postgresql_admin_login.name
          admin_password = azurerm_key_vault_secret.prod_grouper_postgresql_admin_password.name
          host           = azurerm_key_vault_secret.prod_grouper_postgresql_host.name
          database       = azurerm_key_vault_secret.prod_grouper_postgresql_database.name
        }
      }
      grouper_postgresql = {
        name             = azurerm_postgresql_flexible_server.prod_grouper.name
        id               = azurerm_postgresql_flexible_server.prod_grouper.id
        fqdn             = azurerm_postgresql_flexible_server.prod_grouper.fqdn
        database_name    = azurerm_postgresql_flexible_server_database.prod_grouper.name
        private_dns_zone = azurerm_private_dns_zone.prod_grouper_postgresql.name
      }
      node_pools = {
        default = var.prod_default_node_pool.name
      }
    }
  }
}
