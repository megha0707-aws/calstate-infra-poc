# /******************************** Dev NETWORK CONFIGURATION **********************************************/

resource "azurerm_virtual_network" "dev-tf-vnet" {
  name                = "${local.dev_name_prefix}-tf-vnet"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  address_space       = local.dev_vnet_address_spaces

  tags = local.dev_tags
}

resource "azurerm_subnet" "dev-appgw-tf-subnet" {
  name                 = local.dev_appgw_subnet_name
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.dev-tf-vnet.name
  address_prefixes     = [local.dev_appgw_cidr]
}

resource "azurerm_subnet" "dev-psql-tf-subnet" {
  name                 = local.dev_psql_subnet_name
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.dev-tf-vnet.name
  address_prefixes     = [local.dev_psql_cidr]

  delegation {
    name = "postgres-flex-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }

  service_endpoints = [
    "Microsoft.Storage",
  ]
}

resource "azurerm_subnet" "dev-aks-tf-subnet" {
  name                 = local.dev_aks_subnet_name
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.dev-tf-vnet.name
  address_prefixes     = [local.dev_aks_node_cidr]

  service_endpoints = [
    "Microsoft.KeyVault",
  ]
}

# /******************************** Prod NETWORK CONFIGURATION **********************************************/

resource "azurerm_virtual_network" "prod-tf-vnet" {
  name                = "${local.prod_name_prefix}-tf-vnet"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  address_space       = local.prod_vnet_address_spaces

  tags = local.prod_tags
}

resource "azurerm_subnet" "prod-appgw-tf-subnet" {
  name                 = local.prod_appgw_subnet_name
  resource_group_name  = azurerm_resource_group.prod.name
  virtual_network_name = azurerm_virtual_network.prod-tf-vnet.name
  address_prefixes     = [local.prod_appgw_cidr]
}

resource "azurerm_subnet" "prod-psql-tf-subnet" {
  name                 = local.prod_psql_subnet_name
  resource_group_name  = azurerm_resource_group.prod.name
  virtual_network_name = azurerm_virtual_network.prod-tf-vnet.name
  address_prefixes     = [local.prod_psql_cidr]

  delegation {
    name = "postgres-flex-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }

  service_endpoints = [
    "Microsoft.Storage",
  ]
}

resource "azurerm_subnet" "prod-aks-tf-subnet" {
  name                 = local.prod_aks_subnet_name
  resource_group_name  = azurerm_resource_group.prod.name
  virtual_network_name = azurerm_virtual_network.prod-tf-vnet.name
  address_prefixes     = [local.prod_aks_node_cidr]

  service_endpoints = [
    "Microsoft.KeyVault",
  ]
}
