# /================================ Stage AKS CLUSTER CONFIGURATION ============================================/

resource "azurerm_kubernetes_cluster" "stage_aks_cluster" {
  name                = local.stage_aks_cluster_name
  location            = azurerm_resource_group.stage.location
  resource_group_name = azurerm_resource_group.stage.name
  dns_prefix          = "${local.stage_name_prefix}-aks"

  automatic_upgrade_channel = "patch"
  private_cluster_enabled   = false
  sku_tier                  = var.stage_aks_sku_tier

  default_node_pool {
    name                   = var.stage_default_node_pool.name
    node_count             = var.stage_default_node_pool.node_count
    vm_size                = var.stage_default_node_pool.vm_size
    vnet_subnet_id         = azurerm_subnet.stage-aks-tf-subnet.id
    type                   = "VirtualMachineScaleSets"
    node_public_ip_enabled = var.stage_default_node_pool.node_public_ip_enabled

    upgrade_settings {
      drain_timeout_in_minutes      = var.stage_default_node_pool.drain_timeout_in_minutes
      max_surge                     = var.stage_default_node_pool.max_surge
      node_soak_duration_in_minutes = var.stage_default_node_pool.node_soak_duration_in_minutes
    }
  }

  network_profile {
    network_plugin      = var.stage_network_profile.network_plugin
    network_plugin_mode = var.stage_network_profile.network_plugin_mode
    pod_cidr            = var.stage_network_profile.pod_cidr
    service_cidr        = var.stage_network_profile.service_cidr
    dns_service_ip      = var.stage_network_profile.dns_service_ip
  }

  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  web_app_routing {
    dns_zone_ids = []
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  # Container Insights is intentionally disabled by default to avoid unexpected
  # Log Analytics ingestion cost. Uncomment when the environment is ready.
  # oms_agent {
  #   log_analytics_workspace_id      = azurerm_log_analytics_workspace.stage.id
  #   msi_auth_for_monitoring_enabled = true
  # }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      upgrade_override,
    ]
  }

  depends_on = [azurerm_log_analytics_workspace.stage]
}

resource "azurerm_role_assignment" "stage_acr_pull" {
  scope                = azurerm_container_registry.stage.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.stage_aks_cluster.kubelet_identity[0].object_id
}

# /================================ Prod AKS CLUSTER CONFIGURATION ============================================/

resource "azurerm_kubernetes_cluster" "prod_aks_cluster" {
  name                = local.prod_aks_cluster_name
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  dns_prefix          = "${local.prod_name_prefix}-aks"

  private_cluster_enabled = false
  sku_tier                = var.prod_aks_sku_tier

  default_node_pool {
    name                   = var.prod_default_node_pool.name
    node_count             = var.prod_default_node_pool.node_count
    vm_size                = var.prod_default_node_pool.vm_size
    vnet_subnet_id         = azurerm_subnet.prod-aks-tf-subnet.id
    type                   = "VirtualMachineScaleSets"
    node_public_ip_enabled = var.prod_default_node_pool.node_public_ip_enabled

    upgrade_settings {
      drain_timeout_in_minutes      = var.prod_default_node_pool.drain_timeout_in_minutes
      max_surge                     = var.prod_default_node_pool.max_surge
      node_soak_duration_in_minutes = var.prod_default_node_pool.node_soak_duration_in_minutes
    }
  }

  network_profile {
    network_plugin      = var.prod_network_profile.network_plugin
    network_plugin_mode = var.prod_network_profile.network_plugin_mode
    pod_cidr            = var.prod_network_profile.pod_cidr
    service_cidr        = var.prod_network_profile.service_cidr
    dns_service_ip      = var.prod_network_profile.dns_service_ip
  }

  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  web_app_routing {
    dns_zone_ids = []
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
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

  lifecycle {
    ignore_changes = [
      upgrade_override,
    ]
  }

  depends_on = [azurerm_log_analytics_workspace.prod]
}

resource "azurerm_role_assignment" "prod_acr_pull" {
  scope                = azurerm_container_registry.prod.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.prod_aks_cluster.kubelet_identity[0].object_id
}
