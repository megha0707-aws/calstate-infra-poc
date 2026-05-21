locals {
  dev_name_prefix  = "${var.deployment_name}-${var.prefix.dev}"
  prod_name_prefix = "${var.deployment_name}-${var.prefix.prod}"

  dev_resource_group_name  = coalesce(var.resource_group_name_dev, "rg-${local.dev_name_prefix}")
  prod_resource_group_name = coalesce(var.resource_group_name_prod, "rg-${local.prod_name_prefix}")

  dev_acr_name  = var.dev_acr_name
  prod_acr_name = var.prod_acr_name

  assigned_network_cidr = "10.247.80.0/20"

  dev_vnet_cidr     = "10.247.80.0/23"
  dev_appgw_cidr    = "10.247.80.0/24"
  dev_psql_cidr     = "10.247.81.0/27"
  dev_aks_node_cidr = "10.247.81.32/27"

  prod_vnet_cidr     = "10.247.82.0/23"
  prod_appgw_cidr    = "10.247.82.0/24"
  prod_psql_cidr     = "10.247.83.0/27"
  prod_aks_node_cidr = "10.247.83.32/27"

  dev_vnet_address_spaces  = [local.dev_vnet_cidr]
  prod_vnet_address_spaces = [local.prod_vnet_cidr]

  dev_appgw_subnet_name = "${local.dev_name_prefix}-tf-appgw-subnet"
  dev_psql_subnet_name  = "${local.dev_name_prefix}-tf-psql-subnet"
  dev_aks_subnet_name   = "${local.dev_name_prefix}-tf-aks-subnet"

  prod_appgw_subnet_name = "${local.prod_name_prefix}-tf-appgw-subnet"
  prod_psql_subnet_name  = "${local.prod_name_prefix}-tf-psql-subnet"
  prod_aks_subnet_name   = "${local.prod_name_prefix}-tf-aks-subnet"

  dev_aks_cluster_name  = "aks-${local.dev_name_prefix}-cluster"
  prod_aks_cluster_name = "aks-${local.prod_name_prefix}-cluster"

  dev_grouper_postgresql_server_name  = "psql-${local.dev_name_prefix}-grouper"
  prod_grouper_postgresql_server_name = "psql-${local.prod_name_prefix}-grouper"

  dev_tags = {
    ManagedBy   = "Terraform"
    Environment = "dev"
    Workload    = local.dev_resource_group_name
  }

  prod_tags = {
    ManagedBy   = "Terraform"
    Environment = "prod"
    Workload    = local.prod_resource_group_name
  }
}
