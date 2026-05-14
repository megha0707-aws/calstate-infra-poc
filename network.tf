# /******************************** Stage NETWORK CONFIGURATION **********************************************/

resource "azurerm_virtual_network" "stage-tf-vnet" {
  name                = "${local.stage_name_prefix}-tf-vnet"
  location            = azurerm_resource_group.stage.location
  resource_group_name = azurerm_resource_group.stage.name
  address_space       = [local.stage_vnet_cidr]

  tags = merge(local.common_tags, {
    env = "stage"
  })
}

resource "azurerm_subnet" "stage-appgw-tf-subnet" {
  name                 = "${local.stage_name_prefix}-tf-appgw-subnet"
  resource_group_name  = azurerm_resource_group.stage.name
  virtual_network_name = azurerm_virtual_network.stage-tf-vnet.name
  address_prefixes     = [local.stage_appgw_cidr]

  depends_on = [azurerm_virtual_network.stage-tf-vnet]
}

resource "azurerm_subnet" "stage-psql-tf-subnet" {
  name                 = "${local.stage_name_prefix}-tf-psql-subnet"
  resource_group_name  = azurerm_resource_group.stage.name
  virtual_network_name = azurerm_virtual_network.stage-tf-vnet.name
  address_prefixes     = [local.stage_psql_cidr]

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

  depends_on = [azurerm_virtual_network.stage-tf-vnet]
}

resource "azurerm_subnet" "stage-aks-tf-subnet" {
  name                 = "${local.stage_name_prefix}-tf-aks-subnet"
  resource_group_name  = azurerm_resource_group.stage.name
  virtual_network_name = azurerm_virtual_network.stage-tf-vnet.name
  address_prefixes     = [local.stage_aks_node_cidr]

  service_endpoints = [
    "Microsoft.KeyVault",
  ]

  depends_on = [azurerm_virtual_network.stage-tf-vnet]
}

# /******************************** Prod NETWORK CONFIGURATION **********************************************/

resource "azurerm_virtual_network" "prod-tf-vnet" {
  name                = "${local.prod_name_prefix}-tf-vnet"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  address_space       = [local.prod_vnet_cidr]

  tags = merge(local.common_tags, {
    env = "prod"
  })
}

resource "azurerm_subnet" "prod-appgw-tf-subnet" {
  name                 = "${local.prod_name_prefix}-tf-appgw-subnet"
  resource_group_name  = azurerm_resource_group.prod.name
  virtual_network_name = azurerm_virtual_network.prod-tf-vnet.name
  address_prefixes     = [local.prod_appgw_cidr]

  depends_on = [azurerm_virtual_network.prod-tf-vnet]
}

resource "azurerm_subnet" "prod-psql-tf-subnet" {
  name                 = "${local.prod_name_prefix}-tf-psql-subnet"
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

  depends_on = [azurerm_virtual_network.prod-tf-vnet]
}

resource "azurerm_subnet" "prod-aks-tf-subnet" {
  name                 = "${local.prod_name_prefix}-tf-aks-subnet"
  resource_group_name  = azurerm_resource_group.prod.name
  virtual_network_name = azurerm_virtual_network.prod-tf-vnet.name
  address_prefixes     = [local.prod_aks_node_cidr]

  service_endpoints = [
    "Microsoft.KeyVault",
  ]

  depends_on = [azurerm_virtual_network.prod-tf-vnet]
}
