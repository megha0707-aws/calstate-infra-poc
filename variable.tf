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

variable "stage_network_profile" {
  description = "Network profile configuration for the stage AKS cluster."
  type = object({
    network_plugin      = string
    network_plugin_mode = string
    pod_cidr            = string
    service_cidr        = string
    dns_service_ip      = string
  })
  default = {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    pod_cidr            = "10.244.0.0/24"
    service_cidr        = "10.21.0.0/22"
    dns_service_ip      = "10.21.0.10"
  }
}

variable "prod_network_profile" {
  description = "Network profile configuration for the prod AKS cluster."
  type = object({
    network_plugin      = string
    network_plugin_mode = string
    pod_cidr            = string
    service_cidr        = string
    dns_service_ip      = string
  })
  default = {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    pod_cidr            = "10.245.0.0/24"
    service_cidr        = "10.31.0.0/22"
    dns_service_ip      = "10.31.0.10"
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
