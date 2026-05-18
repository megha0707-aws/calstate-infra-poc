locals {
  dev_name_prefix  = "${var.deployment_name}-${var.prefix.dev}"
  prod_name_prefix = "${var.deployment_name}-${var.prefix.prod}"

  dev_resource_group_name  = coalesce(var.resource_group_name_dev, "rg-${local.dev_name_prefix}")
  prod_resource_group_name = coalesce(var.resource_group_name_prod, "rg-${local.prod_name_prefix}")

  dev_acr_name  = coalesce(var.dev_acr_name, "${substr(replace(local.dev_name_prefix, "-", ""), 0, 41)}acr${random_string.dev_acr_suffix.result}")
  prod_acr_name = coalesce(var.prod_acr_name, "${substr(replace(local.prod_name_prefix, "-", ""), 0, 41)}acr${random_string.prod_acr_suffix.result}")

  dev_vnet_cidr     = "10.239.10.0/24"
  dev_appgw_cidr    = "10.239.10.0/26"
  dev_psql_cidr     = "10.239.10.64/27"
  dev_aks_node_cidr = "10.239.10.96/27"

  prod_vnet_cidr     = "10.239.20.0/24"
  prod_appgw_cidr    = "10.239.20.0/26"
  prod_psql_cidr     = "10.239.20.64/27"
  prod_aks_node_cidr = "10.239.20.96/27"

  dev_aks_cluster_name  = "aks-${local.dev_name_prefix}-cluster"
  prod_aks_cluster_name = "aks-${local.prod_name_prefix}-cluster"

  dev_grouper_postgresql_server_name  = "psql-${local.dev_name_prefix}-grouper"
  prod_grouper_postgresql_server_name = "psql-${local.prod_name_prefix}-grouper"

  common_tags = {
    ManagedBy = "Terraform"
    Project   = var.deployment_name
    App       = "grouper"
  }
}
