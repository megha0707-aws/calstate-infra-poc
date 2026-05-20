# /******************************** Dev MONITORING CONFIGURATION **********************************************/

resource "azurerm_monitor_workspace" "dev" {
  name                = "${local.dev_name_prefix}-monitoring-workspace"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location

  tags = local.dev_tags
}

resource "azurerm_monitor_data_collection_endpoint" "dev" {
  name                = "${local.dev_name_prefix}-data-collection-endpoint"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  kind                = "Linux"

  tags = local.dev_tags
}

resource "azurerm_monitor_data_collection_rule" "dev_dcr" {
  name                        = "${local.dev_name_prefix}-monitoring-data-collection-rule"
  resource_group_name         = azurerm_resource_group.dev.name
  location                    = azurerm_resource_group.dev.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dev.id
  kind                        = "Linux"
  description                 = "DCR for Azure Monitor Metrics Profile (Managed Prometheus)."

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.dev.id
      name               = "MonitoringAccount1"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount1"]
  }

  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }

  tags = local.dev_tags
}

resource "azurerm_monitor_data_collection_rule_association" "dev_rule_association" {
  name                    = "${local.dev_name_prefix}-monitoring-dcr-association"
  target_resource_id      = azurerm_kubernetes_cluster.dev_aks_cluster.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dev_dcr.id
  description             = "Association of data collection rule for dev AKS Managed Prometheus metrics."
}

resource "azurerm_monitor_data_collection_rule_association" "dev_dce_association" {
  name                        = "configurationAccessEndpoint"
  target_resource_id          = azurerm_kubernetes_cluster.dev_aks_cluster.id
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dev.id
  description                 = "Association of data collection endpoint for dev AKS Managed Prometheus metrics."
}

resource "azurerm_dashboard_grafana" "dev" {
  name                  = "${local.dev_name_prefix}-grafana"
  resource_group_name   = azurerm_resource_group.dev.name
  location              = azurerm_resource_group.dev.location
  grafana_major_version = "11"

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.dev.id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.dev_tags
}

resource "azurerm_role_assignment" "dev_grafana_monitoring_reader" {
  scope                = azurerm_monitor_workspace.dev.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.dev.identity[0].principal_id
}

# /******************************** Prod MONITORING CONFIGURATION **********************************************/

resource "azurerm_monitor_workspace" "prod" {
  name                = "${local.prod_name_prefix}-monitoring-workspace"
  resource_group_name = azurerm_resource_group.prod.name
  location            = azurerm_resource_group.prod.location

  tags = local.prod_tags
}

resource "azurerm_monitor_data_collection_endpoint" "prod" {
  name                = "${local.prod_name_prefix}-data-collection-endpoint"
  resource_group_name = azurerm_resource_group.prod.name
  location            = azurerm_resource_group.prod.location
  kind                = "Linux"

  tags = local.prod_tags
}

resource "azurerm_monitor_data_collection_rule" "prod_dcr" {
  name                        = "${local.prod_name_prefix}-monitoring-data-collection-rule"
  resource_group_name         = azurerm_resource_group.prod.name
  location                    = azurerm_resource_group.prod.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prod.id
  kind                        = "Linux"
  description                 = "DCR for Azure Monitor Metrics Profile (Managed Prometheus)."

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.prod.id
      name               = "MonitoringAccount1"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount1"]
  }

  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }

  tags = local.prod_tags
}

resource "azurerm_monitor_data_collection_rule_association" "prod_rule_association" {
  name                    = "${local.prod_name_prefix}-monitoring-dcr-association"
  target_resource_id      = azurerm_kubernetes_cluster.prod_aks_cluster.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prod_dcr.id
  description             = "Association of data collection rule for prod AKS Managed Prometheus metrics."
}

resource "azurerm_monitor_data_collection_rule_association" "prod_dce_association" {
  name                        = "configurationAccessEndpoint"
  target_resource_id          = azurerm_kubernetes_cluster.prod_aks_cluster.id
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prod.id
  description                 = "Association of data collection endpoint for prod AKS Managed Prometheus metrics."
}

resource "azurerm_dashboard_grafana" "prod" {
  name                  = "${local.prod_name_prefix}-grafana"
  resource_group_name   = azurerm_resource_group.prod.name
  location              = azurerm_resource_group.prod.location
  grafana_major_version = "11"

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.prod.id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.prod_tags
}

resource "azurerm_role_assignment" "prod_grafana_monitoring_reader" {
  scope                = azurerm_monitor_workspace.prod.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.prod.identity[0].principal_id
}
