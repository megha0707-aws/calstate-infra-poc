# /******************************** Shared Grouper AKS S2S VPN CONFIGURATION **********************************************/

resource "terraform_data" "grouper_aks_s2s_vpn_required_inputs" {
  count = var.enable_grouper_aks_s2s_vpn ? 1 : 0

  input = true

  lifecycle {
    precondition {
      condition = (
        var.onprem_palo_alto_public_ip != null &&
        length(var.prod_onprem_database_cidrs) > 0
      )
      error_message = "When enable_grouper_aks_s2s_vpn is true, set onprem_palo_alto_public_ip and prod_onprem_database_cidrs. If grouper_aks_s2s_onprem_shared_key is null, Terraform generates one and writes it to the existing dev/prod Key Vaults."
    }
  }
}

resource "azurerm_public_ip" "grouper_aks_vpn_gateway" {
  count = var.enable_grouper_aks_s2s_vpn ? 1 : 0

  name                = local.grouper_aks_vpn_gateway_public_ip_name
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]

  tags = local.hub_tags

  depends_on = [terraform_data.grouper_aks_s2s_vpn_required_inputs]
}

resource "azurerm_virtual_network_gateway" "grouper_aks" {
  count = var.enable_grouper_aks_s2s_vpn ? 1 : 0

  name                = local.grouper_aks_vpn_gateway_name
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.grouper_aks_vpn_gateway_sku
  active_active       = false
  enable_bgp          = false

  ip_configuration {
    name                          = local.grouper_aks_vpn_gateway_ip_configuration_name
    public_ip_address_id          = azurerm_public_ip.grouper_aks_vpn_gateway[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.hub-gateway-subnet.id
  }

  tags = local.hub_tags

  depends_on = [terraform_data.grouper_aks_s2s_vpn_required_inputs]
}

resource "azurerm_local_network_gateway" "grouper_aks_onprem_palo_alto" {
  count = var.enable_grouper_aks_s2s_vpn ? 1 : 0

  name                = local.grouper_aks_onprem_palo_alto_lng_name
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  gateway_address     = var.onprem_palo_alto_public_ip
  address_space       = var.prod_onprem_database_cidrs

  tags = local.hub_tags

  depends_on = [terraform_data.grouper_aks_s2s_vpn_required_inputs]
}

resource "azurerm_virtual_network_gateway_connection" "grouper_aks_onprem_palo_alto" {
  count = var.enable_grouper_aks_s2s_vpn ? 1 : 0

  name                       = local.grouper_aks_onprem_palo_alto_connection_name
  resource_group_name        = azurerm_resource_group.hub.name
  location                   = azurerm_resource_group.hub.location
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.grouper_aks[0].id
  local_network_gateway_id   = azurerm_local_network_gateway.grouper_aks_onprem_palo_alto[0].id
  connection_protocol        = "IKEv2"
  shared_key                 = local.grouper_aks_s2s_onprem_shared_key

  ipsec_policy {
    dh_group         = var.grouper_aks_s2s_ipsec_policy.dh_group
    ike_encryption   = var.grouper_aks_s2s_ipsec_policy.ike_encryption
    ike_integrity    = var.grouper_aks_s2s_ipsec_policy.ike_integrity
    ipsec_encryption = var.grouper_aks_s2s_ipsec_policy.ipsec_encryption
    ipsec_integrity  = var.grouper_aks_s2s_ipsec_policy.ipsec_integrity
    pfs_group        = var.grouper_aks_s2s_ipsec_policy.pfs_group
    sa_datasize      = var.grouper_aks_s2s_ipsec_policy.sa_datasize
    sa_lifetime      = var.grouper_aks_s2s_ipsec_policy.sa_lifetime
  }

  tags = local.hub_tags

  depends_on = [terraform_data.grouper_aks_s2s_vpn_required_inputs]
}
