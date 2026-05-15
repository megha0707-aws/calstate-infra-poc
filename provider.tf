terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.57.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.8.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
}

provider "kubernetes" {
  alias                  = "stage"
  host                   = azurerm_kubernetes_cluster.stage_aks_cluster.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.stage_aks_cluster.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.stage_aks_cluster.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.stage_aks_cluster.kube_config[0].cluster_ca_certificate)
}

provider "kubernetes" {
  alias                  = "prod"
  host                   = azurerm_kubernetes_cluster.prod_aks_cluster.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.prod_aks_cluster.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.prod_aks_cluster.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.prod_aks_cluster.kube_config[0].cluster_ca_certificate)
}
