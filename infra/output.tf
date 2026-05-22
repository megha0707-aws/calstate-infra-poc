output "configuration_summary" {
  description = "Summary of the dedicated Grouper AKS infrastructure template."
  value = {
    hub = {
      region         = azurerm_resource_group.hub.location
      resource_group = azurerm_resource_group.hub.name
      virtual_network = {
        name = azurerm_virtual_network.hub-tf-vnet.name
        id   = azurerm_virtual_network.hub-tf-vnet.id
      }
      subnets = {
        gateway = azurerm_subnet.hub-gateway-subnet.id
        bastion = azurerm_subnet.hub-bastion-subnet.id
      }
      peerings = {
        hub_to_dev  = azurerm_virtual_network_peering.hub_to_dev.name
        dev_to_hub  = azurerm_virtual_network_peering.dev_to_hub.name
        hub_to_prod = azurerm_virtual_network_peering.hub_to_prod.name
        prod_to_hub = azurerm_virtual_network_peering.prod_to_hub.name
      }
      s2s_vpn = {
        enabled                       = var.enable_grouper_aks_s2s_vpn
        gateway_name                  = try(azurerm_virtual_network_gateway.grouper_aks[0].name, null)
        gateway_public_ip_name        = try(azurerm_public_ip.grouper_aks_vpn_gateway[0].name, null)
        gateway_public_ip_address     = try(azurerm_public_ip.grouper_aks_vpn_gateway[0].ip_address, null)
        local_network_gateway_name    = try(azurerm_local_network_gateway.grouper_aks_onprem_palo_alto[0].name, null)
        virtual_network_connection    = try(azurerm_virtual_network_gateway_connection.grouper_aks_onprem_palo_alto[0].name, null)
        prod_onprem_database_cidrs    = var.prod_onprem_database_cidrs
        gateway_transit_on_peerings   = var.enable_grouper_aks_s2s_vpn
        route_model                   = "static"
        azure_vpn_gateway_bgp_enabled = false
        key_vault_secret_names = {
          shared_key                     = try(azurerm_key_vault_secret.dev_grouper_aks_s2s_onprem_shared_key[0].name, null)
          written_to_existing_key_vaults = [data.azurerm_key_vault.dev.name, data.azurerm_key_vault.prod.name]
        }
      }
    }

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
        app_gateway      = azurerm_subnet.dev-appgw-tf-subnet.id
        postgresql       = azurerm_subnet.dev-psql-tf-subnet.id
        infra            = azurerm_subnet.dev-infra-tf-subnet.id
        private_endpoint = azurerm_subnet.dev-private-endpoint-tf-subnet.id
        aks              = azurerm_subnet.dev-aks-tf-subnet.id
      }
      container_registry = {
        name         = azurerm_container_registry.dev.name
        login_server = azurerm_container_registry.dev.login_server
      }
      log_analytics = {
        name = azurerm_log_analytics_workspace.dev.name
        id   = azurerm_log_analytics_workspace.dev.id
      }
      monitoring = {
        monitor_workspace_id        = azurerm_monitor_workspace.dev.id
        data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dev.id
        data_collection_rule_id     = azurerm_monitor_data_collection_rule.dev_dcr.id
        grafana_id                  = azurerm_dashboard_grafana.dev.id
        grafana_endpoint            = azurerm_dashboard_grafana.dev.endpoint
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
        default  = var.dev_default_node_pool.name
        max_pods = var.dev_default_node_pool.max_pods
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
        app_gateway      = azurerm_subnet.prod-appgw-tf-subnet.id
        postgresql       = azurerm_subnet.prod-psql-tf-subnet.id
        infra            = azurerm_subnet.prod-infra-tf-subnet.id
        private_endpoint = azurerm_subnet.prod-private-endpoint-tf-subnet.id
        aks              = azurerm_subnet.prod-aks-tf-subnet.id
      }
      container_registry = {
        name         = azurerm_container_registry.prod.name
        login_server = azurerm_container_registry.prod.login_server
      }
      log_analytics = {
        name = azurerm_log_analytics_workspace.prod.name
        id   = azurerm_log_analytics_workspace.prod.id
      }
      monitoring = {
        monitor_workspace_id        = azurerm_monitor_workspace.prod.id
        data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prod.id
        data_collection_rule_id     = azurerm_monitor_data_collection_rule.prod_dcr.id
        grafana_id                  = azurerm_dashboard_grafana.prod.id
        grafana_endpoint            = azurerm_dashboard_grafana.prod.endpoint
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
        default  = var.prod_default_node_pool.name
        max_pods = var.prod_default_node_pool.max_pods
      }
    }
  }
}
