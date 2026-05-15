variable "subscription_id" {
  description = "Azure subscription ID for the DCS shared AKS deployment."
  type        = string
  default     = "REPLACE_WITH_SUBSCRIPTION_ID"
}

variable "location" {
  description = "Azure region for stage and prod infrastructure."
  type        = string
  default     = "westus2"
}

variable "deployment_name" {
  description = "Short deployment name used to keep resource names unique to this stack."
  type        = string
  default     = "dcs-apps"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,30}$", var.deployment_name))
    error_message = "deployment_name must be 3-30 characters and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "resource_group_name_stage" {
  description = "Optional stage resource group name. Leave null to derive one from deployment_name and prefix.stage."
  type        = string
  default     = null

  validation {
    condition     = var.resource_group_name_stage == null || can(regex("^[A-Za-z0-9._()\\-]{1,90}$", var.resource_group_name_stage))
    error_message = "resource_group_name_stage must be 1-90 Azure-compatible resource group name characters when set."
  }
}

variable "resource_group_name_prod" {
  description = "Optional prod resource group name. Leave null to derive one from deployment_name and prefix.prod."
  type        = string
  default     = null

  validation {
    condition     = var.resource_group_name_prod == null || can(regex("^[A-Za-z0-9._()\\-]{1,90}$", var.resource_group_name_prod))
    error_message = "resource_group_name_prod must be 1-90 Azure-compatible resource group name characters when set."
  }
}

variable "prefix" {
  description = "Environment labels appended to deployment_name for Azure resource names."
  type        = map(string)
  default = {
    stage = "stage"
    prod  = "prod"
  }

  validation {
    condition     = contains(keys(var.prefix), "stage") && contains(keys(var.prefix), "prod")
    error_message = "prefix must include stage and prod keys."
  }

  validation {
    condition = alltrue([
      for prefix in values(var.prefix) : can(regex("^[a-z0-9-]{2,20}$", prefix))
    ])
    error_message = "Each prefix value must be 2-20 characters and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "authorized_ip_ranges" {
  description = "CIDRs allowed to access the AKS API server."
  type        = list(string)
  default     = ["137.145.0.0/16"]
}

variable "stage_aks_sku_tier" {
  description = "AKS pricing tier for the stage cluster."
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.stage_aks_sku_tier)
    error_message = "stage_aks_sku_tier must be one of Free, Standard, or Premium."
  }
}

variable "prod_aks_sku_tier" {
  description = "AKS pricing tier for the prod cluster."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.prod_aks_sku_tier)
    error_message = "prod_aks_sku_tier must be one of Free, Standard, or Premium."
  }
}

variable "stage_default_node_pool" {
  description = "Configuration for the stage default AKS node pool."
  type = object({
    name                          = string
    vm_size                       = string
    node_count                    = number
    node_public_ip_enabled        = bool
    drain_timeout_in_minutes      = number
    max_surge                     = string
    node_soak_duration_in_minutes = number
  })
  default = {
    name                          = "default"
    vm_size                       = "Standard_D4ds_v6"
    node_count                    = 3
    node_public_ip_enabled        = false
    drain_timeout_in_minutes      = 0
    max_surge                     = "10%"
    node_soak_duration_in_minutes = 0
  }
}

variable "prod_default_node_pool" {
  description = "Configuration for the prod default AKS node pool."
  type = object({
    name                          = string
    vm_size                       = string
    node_count                    = number
    node_public_ip_enabled        = bool
    drain_timeout_in_minutes      = number
    max_surge                     = string
    node_soak_duration_in_minutes = number
  })
  default = {
    name                          = "default"
    vm_size                       = "Standard_D4ds_v6"
    node_count                    = 3
    node_public_ip_enabled        = false
    drain_timeout_in_minutes      = 0
    max_surge                     = "10%"
    node_soak_duration_in_minutes = 0
  }
}

variable "grouper_namespace" {
  description = "Kubernetes namespace reserved for Grouper workloads."
  type        = string
  default     = "grouper"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.grouper_namespace))
    error_message = "grouper_namespace must be a valid Kubernetes namespace name."
  }
}

variable "stage_grouper_node_pool" {
  description = "Configuration for the stage Grouper user node pool."
  type = object({
    name                          = string
    vm_size                       = string
    node_count                    = number
    mode                          = string
    node_labels                   = map(string)
    node_taints                   = list(string)
    drain_timeout_in_minutes      = number
    max_surge                     = string
    node_soak_duration_in_minutes = number
  })
  default = {
    name                          = "grouper"
    vm_size                       = "Standard_D4ds_v6"
    node_count                    = 1
    mode                          = "User"
    node_labels                   = { workload = "grouper" }
    node_taints                   = ["workload=grouper:NoSchedule"]
    drain_timeout_in_minutes      = 0
    max_surge                     = "10%"
    node_soak_duration_in_minutes = 0
  }
}

variable "prod_grouper_node_pool" {
  description = "Configuration for the prod Grouper user node pool."
  type = object({
    name                          = string
    vm_size                       = string
    node_count                    = number
    mode                          = string
    node_labels                   = map(string)
    node_taints                   = list(string)
    drain_timeout_in_minutes      = number
    max_surge                     = string
    node_soak_duration_in_minutes = number
  })
  default = {
    name                          = "grouper"
    vm_size                       = "Standard_D4ds_v6"
    node_count                    = 2
    mode                          = "User"
    node_labels                   = { workload = "grouper" }
    node_taints                   = ["workload=grouper:NoSchedule"]
    drain_timeout_in_minutes      = 0
    max_surge                     = "10%"
    node_soak_duration_in_minutes = 0
  }
}

variable "stage_network_profile" {
  description = "Network profile configuration for the stage AKS cluster."
  type = object({
    network_plugin      = string
    network_plugin_mode = string
    network_data_plane  = string
    network_policy      = string
    pod_cidr            = string
    service_cidr        = string
    dns_service_ip      = string
  })
  default = {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    pod_cidr            = "10.22.0.0/20"
    service_cidr        = "10.21.0.0/21"
    dns_service_ip      = "10.21.0.10"
  }
}

variable "prod_network_profile" {
  description = "Network profile configuration for the prod AKS cluster."
  type = object({
    network_plugin      = string
    network_plugin_mode = string
    network_data_plane  = string
    network_policy      = string
    pod_cidr            = string
    service_cidr        = string
    dns_service_ip      = string
  })
  default = {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    pod_cidr            = "10.32.0.0/20"
    service_cidr        = "10.31.0.0/21"
    dns_service_ip      = "10.31.0.10"
  }
}

variable "stage_grouper_postgresql" {
  description = "Configuration for the stage Grouper PostgreSQL Flexible Server."
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
    version                      = "16"
    sku_name                     = "B_Standard_B1ms"
    storage_mb                   = 32768
    backup_retention_days        = 7
    geo_redundant_backup_enabled = false
    database_name                = "grouper"
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
    version                      = "16"
    sku_name                     = "GP_Standard_D2ds_v5"
    storage_mb                   = 65536
    backup_retention_days        = 14
    geo_redundant_backup_enabled = false
    database_name                = "grouper"
  }
}

variable "stage_acr_name" {
  description = "Optional globally unique Azure Container Registry name for stage. Leave null to generate one with a stable random suffix."
  type        = string
  default     = null

  validation {
    condition     = var.stage_acr_name == null || can(regex("^[a-zA-Z0-9]{5,50}$", var.stage_acr_name))
    error_message = "stage_acr_name must be 5-50 alphanumeric characters when set."
  }
}

variable "prod_acr_name" {
  description = "Optional globally unique Azure Container Registry name for prod. Leave null to generate one with a stable random suffix."
  type        = string
  default     = null

  validation {
    condition     = var.prod_acr_name == null || can(regex("^[a-zA-Z0-9]{5,50}$", var.prod_acr_name))
    error_message = "prod_acr_name must be 5-50 alphanumeric characters when set."
  }
}
