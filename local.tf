locals {
  stage_name_prefix = "${var.deployment_name}-${var.prefix.stage}"
  prod_name_prefix  = "${var.deployment_name}-${var.prefix.prod}"

  stage_resource_group_name = coalesce(var.resource_group_name_stage, "rg-${local.stage_name_prefix}")
  prod_resource_group_name  = coalesce(var.resource_group_name_prod, "rg-${local.prod_name_prefix}")

  stage_acr_name = coalesce(var.stage_acr_name, "${substr(replace(local.stage_name_prefix, "-", ""), 0, 41)}acr${random_string.stage_acr_suffix.result}")
  prod_acr_name  = coalesce(var.prod_acr_name, "${substr(replace(local.prod_name_prefix, "-", ""), 0, 41)}acr${random_string.prod_acr_suffix.result}")

  stage_vnet_cidr     = "10.20.0.0/16"
  stage_appgw_cidr    = "10.20.4.0/26"
  stage_psql_cidr     = "10.20.6.0/27"
  stage_aks_node_cidr = "10.20.8.0/24"

  prod_vnet_cidr     = "10.30.0.0/16"
  prod_appgw_cidr    = "10.30.4.0/26"
  prod_psql_cidr     = "10.30.6.0/27"
  prod_aks_node_cidr = "10.30.8.0/24"

  stage_aks_cluster_name = "aks-${local.stage_name_prefix}-cluster"
  prod_aks_cluster_name  = "aks-${local.prod_name_prefix}-cluster"

  stage_grouper_postgresql_server_name = "psql-${local.stage_name_prefix}-grouper"
  prod_grouper_postgresql_server_name  = "psql-${local.prod_name_prefix}-grouper"

  common_tags = {
    ManagedBy = "Terraform"
    Project   = var.deployment_name
  }
}
