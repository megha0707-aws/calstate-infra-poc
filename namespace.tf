resource "kubernetes_namespace_v1" "stage_grouper" {
  provider = kubernetes.stage

  metadata {
    name = var.grouper_namespace

    labels = {
      app       = "grouper"
      workload  = "grouper"
      managedBy = "terraform"
    }
  }

  depends_on = [azurerm_kubernetes_cluster_node_pool.stage_grouper]
}

resource "kubernetes_namespace_v1" "prod_grouper" {
  provider = kubernetes.prod

  metadata {
    name = var.grouper_namespace

    labels = {
      app       = "grouper"
      workload  = "grouper"
      managedBy = "terraform"
    }
  }

  depends_on = [azurerm_kubernetes_cluster_node_pool.prod_grouper]
}
