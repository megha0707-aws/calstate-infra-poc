# /================================ Dev Grouper AKS CLUSTER CONFIGURATION ============================================/

resource "azurerm_kubernetes_cluster" "dev_aks_cluster" {
  name                = local.dev_aks_cluster_name
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  dns_prefix          = "${local.dev_name_prefix}-aks"

  private_cluster_enabled = false
  oidc_issuer_enabled     = true
  
  sku_tier                = var.dev_aks_sku_tier

  default_node_pool {
    name                        = var.dev_default_node_pool.name
    node_count                  = var.dev_default_node_pool.node_count
    vm_size                     = var.dev_default_node_pool.vm_size
    max_pods                    = var.dev_default_node_pool.max_pods
    vnet_subnet_id              = azurerm_subnet.dev-aks-tf-subnet.id
    type                        = "VirtualMachineScaleSets"
    node_public_ip_enabled      = var.dev_default_node_pool.node_public_ip_enabled
    temporary_name_for_rotation = var.dev_default_node_pool.temporary_name_for_rotation

    upgrade_settings {
      drain_timeout_in_minutes      = var.dev_default_node_pool.drain_timeout_in_minutes
      max_surge                     = var.dev_default_node_pool.max_surge
      node_soak_duration_in_minutes = var.dev_default_node_pool.node_soak_duration_in_minutes
    }
  }

  network_profile {
    network_plugin     = var.dev_network_profile.network_plugin
    network_data_plane = var.dev_network_profile.network_data_plane
    network_policy     = var.dev_network_profile.network_policy
    service_cidr       = var.dev_network_profile.service_cidr
    dns_service_ip     = var.dev_network_profile.dns_service_ip
  }

  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  monitor_metrics {
    annotations_allowed = null
    labels_allowed      = null
  }

  # Container Insights is intentionally disabled by default to avoid unexpected
  # Log Analytics ingestion cost. Uncomment when the environment is ready.
  # oms_agent {
  #   log_analytics_workspace_id      = azurerm_log_analytics_workspace.dev.id
  #   msi_auth_for_monitoring_enabled = true
  # }

  identity {
    type = "SystemAssigned"
  }

  tags = local.dev_tags

  lifecycle {
    ignore_changes = [
      upgrade_override,
    ]

    replace_triggered_by = [
      azurerm_subnet.dev-aks-tf-subnet.id,
    ]
  }

  depends_on = [azurerm_log_analytics_workspace.dev]
}

resource "azurerm_role_assignment" "dev_acr_pull" {
  scope                = azurerm_container_registry.dev.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.dev_aks_cluster.kubelet_identity[0].object_id
}

# /================================ Prod Grouper AKS CLUSTER CONFIGURATION ============================================/

resource "azurerm_kubernetes_cluster" "prod_aks_cluster" {
  name                = local.prod_aks_cluster_name
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  dns_prefix          = "${local.prod_name_prefix}-aks"

  oidc_issuer_enabled     = true
  private_cluster_enabled = false
  sku_tier                = var.prod_aks_sku_tier

  default_node_pool {
    name                        = var.prod_default_node_pool.name
    node_count                  = var.prod_default_node_pool.node_count
    vm_size                     = var.prod_default_node_pool.vm_size
    max_pods                    = var.prod_default_node_pool.max_pods
    vnet_subnet_id              = azurerm_subnet.prod-aks-tf-subnet.id
    type                        = "VirtualMachineScaleSets"
    node_public_ip_enabled      = var.prod_default_node_pool.node_public_ip_enabled
    temporary_name_for_rotation = var.prod_default_node_pool.temporary_name_for_rotation

    upgrade_settings {
      drain_timeout_in_minutes      = var.prod_default_node_pool.drain_timeout_in_minutes
      max_surge                     = var.prod_default_node_pool.max_surge
      node_soak_duration_in_minutes = var.prod_default_node_pool.node_soak_duration_in_minutes
    }
  }

  network_profile {
    network_plugin     = var.prod_network_profile.network_plugin
    network_data_plane = var.prod_network_profile.network_data_plane
    network_policy     = var.prod_network_profile.network_policy
    service_cidr       = var.prod_network_profile.service_cidr
    dns_service_ip     = var.prod_network_profile.dns_service_ip
  }

  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  monitor_metrics {
    annotations_allowed = null
    labels_allowed      = null
  }

  # Container Insights is intentionally disabled by default to avoid unexpected
  # Log Analytics ingestion cost. Uncomment when the environment is ready.
  # oms_agent {
  #   log_analytics_workspace_id      = azurerm_log_analytics_workspace.prod.id
  #   msi_auth_for_monitoring_enabled = true
  # }

  identity {
    type = "SystemAssigned"
  }

  tags = local.prod_tags

  lifecycle {
    ignore_changes = [
      upgrade_override,
    ]

    replace_triggered_by = [
      azurerm_subnet.prod-aks-tf-subnet.id,
    ]
  }

  depends_on = [azurerm_log_analytics_workspace.prod]
}

resource "azurerm_role_assignment" "prod_acr_pull" {
  scope                = azurerm_container_registry.prod.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.prod_aks_cluster.kubelet_identity[0].object_id
}
