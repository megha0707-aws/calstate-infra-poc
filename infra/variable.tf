variable "subscription_id" {
  description = "Azure subscription ID for the Grouper AKS deployment."
  type        = string
  default     = "f4f3ec7d-9d6f-4752-bdcc-440ed90734fe"
}

variable "location" {
  description = "Azure region for dev and prod Grouper infrastructure."
  type        = string
  default     = "westus2"
}

variable "deployment_name" {
  description = "Short deployment name used to keep Grouper resource names unique."
  type        = string
  default     = "grouper"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,30}$", var.deployment_name))
    error_message = "deployment_name must be 3-30 characters and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "resource_group_name_dev" {
  description = "Optional dev resource group name. Leave null to derive one from deployment_name and prefix.dev."
  type        = string
  default     = "Grouper-Dev"

  validation {
    condition     = var.resource_group_name_dev == null || can(regex("^[A-Za-z0-9._()\\-]{1,90}$", var.resource_group_name_dev))
    error_message = "resource_group_name_dev must be 1-90 Azure-compatible resource group name characters when set."
  }
}

variable "resource_group_name_prod" {
  description = "Optional prod resource group name. Leave null to derive one from deployment_name and prefix.prod."
  type        = string
  default     = "Grouper-Prod"

  validation {
    condition     = var.resource_group_name_prod == null || can(regex("^[A-Za-z0-9._()\\-]{1,90}$", var.resource_group_name_prod))
    error_message = "resource_group_name_prod must be 1-90 Azure-compatible resource group name characters when set."
  }
}

variable "resource_group_name_hub" {
  description = "Optional shared hub resource group name for Grouper AKS connectivity. Leave null to derive one from deployment_name."
  type        = string
  default     = "Grouper-AKS-Hub"

  validation {
    condition     = var.resource_group_name_hub == null || can(regex("^[A-Za-z0-9._()\\-]{1,90}$", var.resource_group_name_hub))
    error_message = "resource_group_name_hub must be 1-90 Azure-compatible resource group name characters when set."
  }
}

variable "prefix" {
  description = "Environment labels appended to deployment_name for Azure resource names."
  type        = map(string)
  default = {
    dev  = "dev"
    prod = "prod"
  }

  validation {
    condition     = contains(keys(var.prefix), "dev") && contains(keys(var.prefix), "prod")
    error_message = "prefix must include dev and prod keys."
  }

  validation {
    condition = alltrue([
      for prefix in values(var.prefix) : can(regex("^[a-z0-9-]{2,20}$", prefix))
    ])
    error_message = "Each prefix value must be 2-20 characters and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "authorized_ip_ranges" {
  description = "CIDRs allowed to access the AKS API servers."
  type        = list(string)
  default     = ["137.145.0.0/16", "47.155.238.17/32", "13.64.65.37/32"]
}

variable "app_gateway_allowed_source_address_prefixes" {
  description = "Source address prefixes allowed to reach the Application Gateway frontend listeners."
  type        = list(string)
  default     = ["137.145.0.0/16", "47.155.238.17/32", "13.64.65.37/32"]
}

variable "dev_aks_sku_tier" {
  description = "AKS pricing tier for the dev Grouper cluster."
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.dev_aks_sku_tier)
    error_message = "dev_aks_sku_tier must be one of Free, Standard, or Premium."
  }
}

variable "prod_aks_sku_tier" {
  description = "AKS pricing tier for the prod Grouper cluster."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.prod_aks_sku_tier)
    error_message = "prod_aks_sku_tier must be one of Free, Standard, or Premium."
  }
}

variable "dev_default_node_pool" {
  description = "Configuration for the dev Grouper AKS default node pool."
  type = object({
    name                          = string
    vm_size                       = string
    node_count                    = number
    max_pods                      = number
    node_public_ip_enabled        = bool
    temporary_name_for_rotation   = string
    drain_timeout_in_minutes      = number
    max_surge                     = string
    node_soak_duration_in_minutes = number
  })
  default = {
    name                          = "default"
    vm_size                       = "Standard_D4ads_v5"
    node_count                    = 2
    max_pods                      = 20
    node_public_ip_enabled        = false
    temporary_name_for_rotation   = "tmpdev"
    drain_timeout_in_minutes      = 0
    max_surge                     = "10%"
    node_soak_duration_in_minutes = 0
  }

  validation {
    condition     = var.dev_default_node_pool.max_pods >= 10 && var.dev_default_node_pool.max_pods <= 20
    error_message = "dev_default_node_pool.max_pods must be between 10 and 20 to fit the approved /25 flat AKS subnet design."
  }

  validation {
    condition     = var.dev_default_node_pool.node_count >= 1 && var.dev_default_node_pool.node_count <= 4
    error_message = "dev_default_node_pool.node_count must be between 1 and 4 to fit the approved /25 flat AKS subnet design."
  }

  validation {
    condition     = var.dev_default_node_pool.node_count * var.dev_default_node_pool.max_pods > 30
    error_message = "dev_default_node_pool.node_count multiplied by max_pods must be greater than 30 to satisfy AKS agent pool requirements."
  }
}

variable "prod_default_node_pool" {
  description = "Configuration for the prod Grouper AKS default node pool."
  type = object({
    name                          = string
    vm_size                       = string
    node_count                    = number
    max_pods                      = number
    node_public_ip_enabled        = bool
    temporary_name_for_rotation   = string
    drain_timeout_in_minutes      = number
    max_surge                     = string
    node_soak_duration_in_minutes = number
  })
  default = {
    name                          = "default"
    vm_size                       = "Standard_E4ads_v5"
    node_count                    = 3
    max_pods                      = 20
    node_public_ip_enabled        = false
    temporary_name_for_rotation   = "tmpprod"
    drain_timeout_in_minutes      = 0
    max_surge                     = "10%"
    node_soak_duration_in_minutes = 0
  }

  validation {
    condition     = var.prod_default_node_pool.max_pods >= 10 && var.prod_default_node_pool.max_pods <= 20
    error_message = "prod_default_node_pool.max_pods must be between 10 and 20 to fit the approved /25 flat AKS subnet design."
  }

  validation {
    condition     = var.prod_default_node_pool.node_count >= 1 && var.prod_default_node_pool.node_count <= 4
    error_message = "prod_default_node_pool.node_count must be between 1 and 4 to fit the approved /25 flat AKS subnet design."
  }

  validation {
    condition     = var.prod_default_node_pool.node_count * var.prod_default_node_pool.max_pods > 30
    error_message = "prod_default_node_pool.node_count multiplied by max_pods must be greater than 30 to satisfy AKS agent pool requirements."
  }
}

variable "dev_network_profile" {
  description = "Network profile configuration for the dev Grouper AKS cluster."
  type = object({
    network_plugin     = string
    network_data_plane = string
    network_policy     = string
    service_cidr       = string
    dns_service_ip     = string
  })
  default = {
    network_plugin     = "azure"
    network_data_plane = "cilium"
    network_policy     = "cilium"
    service_cidr       = "10.247.84.0/24"
    dns_service_ip     = "10.247.84.10"
  }
}

variable "prod_network_profile" {
  description = "Network profile configuration for the prod Grouper AKS cluster."
  type = object({
    network_plugin     = string
    network_data_plane = string
    network_policy     = string
    service_cidr       = string
    dns_service_ip     = string
  })
  default = {
    network_plugin     = "azure"
    network_data_plane = "cilium"
    network_policy     = "cilium"
    service_cidr       = "10.247.85.0/24"
    dns_service_ip     = "10.247.85.10"
  }
}

variable "dev_grouper_postgresql" {
  description = "Configuration for the dev Grouper PostgreSQL Flexible Server."
  type = object({
    administrator_login          = string
    version                      = string
    sku_name                     = string
    storage_mb                   = number
    backup_retention_days        = number
    geo_redundant_backup_enabled = bool
    database_name                = string
  })
  default = {
    administrator_login          = "pgadmin"
    version                      = "17"
    sku_name                     = "B_Standard_B1ms"
    storage_mb                   = 32768
    backup_retention_days        = 7
    geo_redundant_backup_enabled = false
    database_name                = "grouper"
  }

  validation {
    condition     = can(tonumber(var.dev_grouper_postgresql.version)) && tonumber(var.dev_grouper_postgresql.version) >= 16
    error_message = "dev_grouper_postgresql.version must be PostgreSQL 16 or newer."
  }
}

variable "prod_grouper_postgresql" {
  description = "Configuration for the prod Grouper PostgreSQL Flexible Server."
  type = object({
    administrator_login          = string
    version                      = string
    sku_name                     = string
    storage_mb                   = number
    backup_retention_days        = number
    geo_redundant_backup_enabled = bool
    database_name                = string
  })
  default = {
    administrator_login          = "pgadmin"
    version                      = "17"
    sku_name                     = "GP_Standard_D2ds_v5"
    storage_mb                   = 65536
    backup_retention_days        = 14
    geo_redundant_backup_enabled = false
    database_name                = "grouper"
  }

  validation {
    condition     = can(tonumber(var.prod_grouper_postgresql.version)) && tonumber(var.prod_grouper_postgresql.version) >= 16
    error_message = "prod_grouper_postgresql.version must be PostgreSQL 16 or newer."
  }
}

variable "dev_acr_name" {
  description = "Globally unique Azure Container Registry name for dev."
  type        = string
  default     = "csugrouperdevacr"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.dev_acr_name))
    error_message = "dev_acr_name must be 5-50 alphanumeric characters."
  }
}

variable "prod_acr_name" {
  description = "Globally unique Azure Container Registry name for prod."
  type        = string
  default     = "csugrouperprodacr"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.prod_acr_name))
    error_message = "prod_acr_name must be 5-50 alphanumeric characters."
  }
}

variable "dev_key_vault_name" {
  description = "Name of the existing manually-managed dev Key Vault used for Grouper PostgreSQL secrets."
  type        = string
  default     = "kv-dev-grouper"

  validation {
    condition     = var.dev_key_vault_name == null || can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.dev_key_vault_name))
    error_message = "dev_key_vault_name must be 3-24 characters, start with a letter, end with a letter or number, and contain only letters, numbers, and hyphens."
  }
}

variable "prod_key_vault_name" {
  description = "Name of the existing manually-managed prod Key Vault used for Grouper PostgreSQL secrets."
  type        = string
  default     = "kv-prod-grouper"

  validation {
    condition     = var.prod_key_vault_name == null || can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.prod_key_vault_name))
    error_message = "prod_key_vault_name must be 3-24 characters, start with a letter, end with a letter or number, and contain only letters, numbers, and hyphens."
  }
}

variable "enable_grouper_aks_s2s_vpn" {
  description = "Whether to create the shared Grouper AKS hub VPN Gateway, local network gateway, and S2S connection to the on-premises Palo Alto firewall."
  type        = bool
  default     = true
}

variable "grouper_aks_connectivity_resource_name_prefix" {
  description = "Azure-facing resource name prefix for shared Grouper AKS VPN connectivity objects. Defaults to the existing enterprise VPN gateway pattern shown in Azure: AZR-prod-<Workload>."
  type        = string
  default     = "AZR-prod-GrouperAKS"

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9.-]{1,70}[A-Za-z0-9]$", var.grouper_aks_connectivity_resource_name_prefix))
    error_message = "grouper_aks_connectivity_resource_name_prefix must be 3-72 characters, start and end with a letter or number, and contain only letters, numbers, periods, and hyphens."
  }
}

variable "grouper_aks_vpn_gateway_sku" {
  description = "Azure VPN Gateway SKU for the shared Grouper AKS hub. Use an AZ SKU for production resiliency."
  type        = string
  default     = "VpnGw1AZ"

  validation {
    condition = contains([
      "VpnGw1AZ",
      "VpnGw2AZ",
      "VpnGw3AZ",
      "VpnGw4AZ",
      "VpnGw5AZ",
    ], var.grouper_aks_vpn_gateway_sku)
    error_message = "grouper_aks_vpn_gateway_sku must be one of VpnGw1AZ, VpnGw2AZ, VpnGw3AZ, VpnGw4AZ, or VpnGw5AZ."
  }
}

variable "onprem_palo_alto_public_ip" {
  description = "Public floating IP address of the on-premises Palo Alto HA pair used for IPsec termination."
  type        = string
  default     = "137.145.10.114"
}

variable "prod_onprem_database_cidrs" {
  description = "Production on-premises database CIDR prefixes reachable over the Grouper AKS S2S VPN tunnel. For static routing, these are the local network gateway address spaces."
  type        = list(string)
  default     = ["137.145.22.135/32"]
}

variable "grouper_aks_s2s_onprem_shared_key" {
  description = "Optional pre-shared key for the Grouper AKS S2S VPN connection. Leave null to let Terraform generate one and write it to both existing dev/prod Key Vaults; Terraform state must still be treated as sensitive."
  type        = string
  default     = null
  sensitive   = true
}

variable "grouper_aks_s2s_ipsec_policy" {
  description = "Modern IKEv2/IPsec policy for the Grouper AKS S2S VPN connection. Palo Alto Phase 1 and Phase 2 settings must match these values."
  type = object({
    dh_group         = string
    ike_encryption   = string
    ike_integrity    = string
    ipsec_encryption = string
    ipsec_integrity  = string
    pfs_group        = string
    sa_datasize      = number
    sa_lifetime      = number
  })
  default = {
    dh_group         = "DHGroup14"
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "PFS14"
    sa_datasize      = 100663296
    sa_lifetime      = 27000
  }
}
