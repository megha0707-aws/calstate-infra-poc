# /******************************** Dev NETWORK SECURITY CONFIGURATION **********************************************/

resource "azurerm_network_security_group" "dev_appgw" {
  name                = "${local.dev_name_prefix}-appgw-nsg"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  tags = merge(local.common_tags, {
    env = "dev"
  })
}

resource "azurerm_network_security_rule" "dev_appgw_frontend_inbound" {
  name                        = "Allow-Frontend-Http-Https-Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefixes     = var.app_gateway_allowed_source_address_prefixes
  destination_address_prefix  = local.dev_appgw_cidr
  resource_group_name         = azurerm_resource_group.dev.name
  network_security_group_name = azurerm_network_security_group.dev_appgw.name
}

resource "azurerm_network_security_rule" "dev_appgw_gateway_manager_inbound" {
  name                        = "Allow-GatewayManager-Inbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = local.dev_appgw_cidr
  resource_group_name         = azurerm_resource_group.dev.name
  network_security_group_name = azurerm_network_security_group.dev_appgw.name
}

resource "azurerm_network_security_rule" "dev_appgw_azure_load_balancer_inbound" {
  name                        = "Allow-AzureLoadBalancer-Inbound"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = local.dev_appgw_cidr
  resource_group_name         = azurerm_resource_group.dev.name
  network_security_group_name = azurerm_network_security_group.dev_appgw.name
}

resource "azurerm_network_security_rule" "dev_appgw_deny_inbound" {
  name                        = "Deny-All-Inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = local.dev_appgw_cidr
  resource_group_name         = azurerm_resource_group.dev.name
  network_security_group_name = azurerm_network_security_group.dev_appgw.name
}

resource "azurerm_subnet_network_security_group_association" "dev_appgw" {
  subnet_id                 = azurerm_subnet.dev-appgw-tf-subnet.id
  network_security_group_id = azurerm_network_security_group.dev_appgw.id
}

resource "azurerm_network_security_group" "dev_psql" {
  name                = "${local.dev_name_prefix}-psql-nsg"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  tags = merge(local.common_tags, {
    env = "dev"
  })
}

resource "azurerm_network_security_rule" "dev_psql_from_aks_inbound" {
  name                        = "Allow-AKS-PostgreSQL-Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = local.dev_aks_node_cidr
  destination_address_prefix  = local.dev_psql_cidr
  resource_group_name         = azurerm_resource_group.dev.name
  network_security_group_name = azurerm_network_security_group.dev_psql.name
}

resource "azurerm_network_security_rule" "dev_psql_intra_subnet_inbound" {
  name                        = "Allow-PostgreSQL-Subnet-Inbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = local.dev_psql_cidr
  destination_address_prefix  = local.dev_psql_cidr
  resource_group_name         = azurerm_resource_group.dev.name
  network_security_group_name = azurerm_network_security_group.dev_psql.name
}

resource "azurerm_network_security_rule" "dev_psql_deny_vnet_inbound" {
  name                        = "Deny-VNet-Inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = local.dev_psql_cidr
  resource_group_name         = azurerm_resource_group.dev.name
  network_security_group_name = azurerm_network_security_group.dev_psql.name
}

resource "azurerm_subnet_network_security_group_association" "dev_psql" {
  subnet_id                 = azurerm_subnet.dev-psql-tf-subnet.id
  network_security_group_id = azurerm_network_security_group.dev_psql.id
}

# /******************************** Prod NETWORK SECURITY CONFIGURATION **********************************************/

resource "azurerm_network_security_group" "prod_appgw" {
  name                = "${local.prod_name_prefix}-appgw-nsg"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name

  tags = merge(local.common_tags, {
    env = "prod"
  })
}

resource "azurerm_network_security_rule" "prod_appgw_frontend_inbound" {
  name                        = "Allow-Frontend-Http-Https-Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefixes     = var.app_gateway_allowed_source_address_prefixes
  destination_address_prefix  = local.prod_appgw_cidr
  resource_group_name         = azurerm_resource_group.prod.name
  network_security_group_name = azurerm_network_security_group.prod_appgw.name
}

resource "azurerm_network_security_rule" "prod_appgw_gateway_manager_inbound" {
  name                        = "Allow-GatewayManager-Inbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = local.prod_appgw_cidr
  resource_group_name         = azurerm_resource_group.prod.name
  network_security_group_name = azurerm_network_security_group.prod_appgw.name
}

resource "azurerm_network_security_rule" "prod_appgw_azure_load_balancer_inbound" {
  name                        = "Allow-AzureLoadBalancer-Inbound"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = local.prod_appgw_cidr
  resource_group_name         = azurerm_resource_group.prod.name
  network_security_group_name = azurerm_network_security_group.prod_appgw.name
}

resource "azurerm_network_security_rule" "prod_appgw_deny_inbound" {
  name                        = "Deny-All-Inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = local.prod_appgw_cidr
  resource_group_name         = azurerm_resource_group.prod.name
  network_security_group_name = azurerm_network_security_group.prod_appgw.name
}

resource "azurerm_subnet_network_security_group_association" "prod_appgw" {
  subnet_id                 = azurerm_subnet.prod-appgw-tf-subnet.id
  network_security_group_id = azurerm_network_security_group.prod_appgw.id
}

resource "azurerm_network_security_group" "prod_psql" {
  name                = "${local.prod_name_prefix}-psql-nsg"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name

  tags = merge(local.common_tags, {
    env = "prod"
  })
}

resource "azurerm_network_security_rule" "prod_psql_from_aks_inbound" {
  name                        = "Allow-AKS-PostgreSQL-Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = local.prod_aks_node_cidr
  destination_address_prefix  = local.prod_psql_cidr
  resource_group_name         = azurerm_resource_group.prod.name
  network_security_group_name = azurerm_network_security_group.prod_psql.name
}

resource "azurerm_network_security_rule" "prod_psql_intra_subnet_inbound" {
  name                        = "Allow-PostgreSQL-Subnet-Inbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = local.prod_psql_cidr
  destination_address_prefix  = local.prod_psql_cidr
  resource_group_name         = azurerm_resource_group.prod.name
  network_security_group_name = azurerm_network_security_group.prod_psql.name
}

resource "azurerm_network_security_rule" "prod_psql_deny_vnet_inbound" {
  name                        = "Deny-VNet-Inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = local.prod_psql_cidr
  resource_group_name         = azurerm_resource_group.prod.name
  network_security_group_name = azurerm_network_security_group.prod_psql.name
}

resource "azurerm_subnet_network_security_group_association" "prod_psql" {
  subnet_id                 = azurerm_subnet.prod-psql-tf-subnet.id
  network_security_group_id = azurerm_network_security_group.prod_psql.id
}
