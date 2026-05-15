output "configuration_summary" {
  description = "Summary of the DCS shared AKS infrastructure template."
  value = {
    stage = {
      region         = azurerm_resource_group.stage.location
      resource_group = azurerm_resource_group.stage.name
      aks = {
        name = azurerm_kubernetes_cluster.stage_aks_cluster.name
        id   = azurerm_kubernetes_cluster.stage_aks_cluster.id
      }
      virtual_network = {
        name = azurerm_virtual_network.stage-tf-vnet.name
        id   = azurerm_virtual_network.stage-tf-vnet.id
      }
      subnets = {
        app_gateway = azurerm_subnet.stage-appgw-tf-subnet.id
        postgresql  = azurerm_subnet.stage-psql-tf-subnet.id
        aks         = azurerm_subnet.stage-aks-tf-subnet.id
      }
      container_registry = {
        name         = azurerm_container_registry.stage.name
        login_server = azurerm_container_registry.stage.login_server
      }
      log_analytics = {
        name = azurerm_log_analytics_workspace.stage.name
        id   = azurerm_log_analytics_workspace.stage.id
      }
      grouper_postgresql = {
        name             = azurerm_postgresql_flexible_server.stage_grouper.name
        id               = azurerm_postgresql_flexible_server.stage_grouper.id
        fqdn             = azurerm_postgresql_flexible_server.stage_grouper.fqdn
        database_name    = azurerm_postgresql_flexible_server_database.stage_grouper.name
        private_dns_zone = azurerm_private_dns_zone.stage_grouper_postgresql.name
      }
      node_pools = {
        system  = var.stage_default_node_pool.name
        grouper = azurerm_kubernetes_cluster_node_pool.stage_grouper.name
      }
      namespaces = {
        grouper = kubernetes_namespace_v1.stage_grouper.metadata[0].name
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
      grouper_postgresql = {
        name             = azurerm_postgresql_flexible_server.prod_grouper.name
        id               = azurerm_postgresql_flexible_server.prod_grouper.id
        fqdn             = azurerm_postgresql_flexible_server.prod_grouper.fqdn
        database_name    = azurerm_postgresql_flexible_server_database.prod_grouper.name
        private_dns_zone = azurerm_private_dns_zone.prod_grouper_postgresql.name
      }
      node_pools = {
        system  = var.prod_default_node_pool.name
        grouper = azurerm_kubernetes_cluster_node_pool.prod_grouper.name
      }
      namespaces = {
        grouper = kubernetes_namespace_v1.prod_grouper.metadata[0].name
      }
    }
  }
}
