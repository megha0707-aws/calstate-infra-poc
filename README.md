# CalState DCS Terraform Infrastructure

Terraform template for shared DCS AKS `stage` and `prod` clusters in **West US 2**. The Azure foundation is universal for DCS application workloads. Grouper is the first app-specific workload and gets its own Kubernetes namespace and dedicated user node pool.

This repo is code only; nothing has been deployed from it yet.

## Architecture

This template prepares the Azure foundation for DCS applications:

- Resource groups for `stage` and `prod`
- VNets for each environment
- Dedicated `/26` Application Gateway subnets
- Dedicated `/27` PostgreSQL Flexible Server delegated subnets
- Private Grouper PostgreSQL Flexible Servers with private DNS
- Dedicated `/24` AKS node subnets
- AKS clusters using Azure CNI Overlay
- Prod AKS cluster using the `Standard` pricing tier / Stage AKS using the `Free` tier
- `Standard_D4ds_v6` default AKS system node pools
- Dedicated Grouper user node pools
- `grouper` Kubernetes namespace in each cluster
- Azure CNI powered by Cilium for network policy enforcement
- Baseline Grouper namespace NetworkPolicies
- Log Analytics workspaces
- Azure Container Registries
- `AcrPull` role assignments from AKS to ACR

## Network Defaults

```text
stage VNet       = 10.20.0.0/16  Azure network for stage resources
stage AppGW      = 10.20.4.0/26  Dedicated Application Gateway subnet
stage PostgreSQL = 10.20.6.0/27  Delegated PostgreSQL Flexible Server subnet
stage AKS nodes  = 10.20.8.0/24  AKS node subnet
stage pods       = 10.22.0.0/20  AKS overlay pod IP range
stage services   = 10.21.0.0/21  Kubernetes ClusterIP service range

prod VNet        = 10.30.0.0/16  Azure network for prod resources
prod AppGW       = 10.30.4.0/26  Dedicated Application Gateway subnet
prod PostgreSQL  = 10.30.6.0/27  Delegated PostgreSQL Flexible Server subnet
prod AKS nodes   = 10.30.8.0/24  AKS node subnet
prod pods        = 10.32.0.0/20  AKS overlay pod IP range
prod services    = 10.31.0.0/21  Kubernetes ClusterIP service range
```

AKS uses Azure CNI Overlay, so pod IPs come from the overlay pod CIDRs, not from the AKS node subnets.

The AKS node and pod ranges are sized for shared clusters with future app-specific node pools and namespaces, not only for the initial Grouper workload.

The network ranges serve different purposes:

- VNet, AppGW, PostgreSQL, and AKS node ranges are real Azure VNet/subnet IP ranges.
- Pod ranges are Kubernetes overlay IPs used by pods inside AKS.
- Service ranges are Kubernetes `ClusterIP` virtual service IPs used inside AKS.
- These ranges do not need to be adjacent, but they must not overlap with each other, peered VNets, VPN/on-prem networks, or other AKS clusters.

## Naming

Defaults:

```text
location        = "westus2"
deployment_name = "dcs-apps"
prefix.stage    = "stage"
prefix.prod     = "prod"
grouper_namespace = "grouper"
```

Example names:

```text
rg-dcs-apps-stage
dcs-apps-stage-tf-vnet
dcs-apps-stage-tf-appgw-subnet
dcs-apps-stage-tf-psql-subnet
dcs-apps-stage-tf-aks-subnet
aks-dcs-apps-stage-cluster
dcs-apps-stage-law-logs
```

ACR names cannot contain hyphens and must be globally unique, so they are generated with stable random suffixes unless `stage_acr_name` or `prod_acr_name` is set.

## Workload Isolation

Grouper workloads are intended to run in the `grouper` namespace on the dedicated `grouper` user node pool. The system/default node pool is kept for AKS and platform components.

Future applications can follow the same pattern: add a dedicated namespace and, when isolation or scaling requires it, a separate app-specific user node pool. This lets new applications be added without rebuilding the AKS environment.

The `grouper` node pool is tainted with `workload=grouper:NoSchedule`, so workloads scheduled there need a matching toleration.

## Network Microsegmentation

AKS is configured with Azure CNI Overlay plus Cilium:

```text
network_plugin      = "azure"
network_plugin_mode = "overlay"
network_data_plane  = "cilium"
network_policy      = "cilium"
```

The Grouper namespace has baseline Kubernetes NetworkPolicies:

- `default-deny`: denies all ingress and egress for Grouper pods unless another policy allows it.
- `allow-dns-egress`: allows Grouper pods to reach CoreDNS in `kube-system` on TCP/UDP 53.

Application-specific allow policies still need to be added with the application manifests, for example ingress-to-UI, UI-to-WS, WS-to-daemon, and Grouper-to-PostgreSQL flows.

## Grouper Database

The PostgreSQL delegated subnet is part of the shared network foundation, but the PostgreSQL Flexible Server created by this template is Grouper-specific:

```text
azurerm_postgresql_flexible_server.stage_grouper
azurerm_postgresql_flexible_server.prod_grouper
```

Future applications that need their own database should add separate database resources rather than reusing the Grouper PostgreSQL server.

## Terraform Resource Aliases

Terraform resource aliases are environment-specific. Shared infrastructure aliases remain app-neutral, while workload aliases identify the application they isolate:

```text
azurerm_kubernetes_cluster_node_pool.stage_grouper
azurerm_kubernetes_cluster_node_pool.prod_grouper
kubernetes_namespace_v1.stage_grouper
kubernetes_namespace_v1.prod_grouper
```

Provider aliases remain environment-specific:

```text
kubernetes.stage
kubernetes.prod
```

## Not Included Yet

- Application Gateway resource
- Key Vault
- Application Insights
- Workload managed identities
- App-specific NetworkPolicies, ingress, app manifests, or ArgoCD bootstrap
- Additional app-specific namespaces or node pools beyond Grouper
- Diagnostic settings beyond the Log Analytics workspace
- Key Vault storage for generated PostgreSQL admin credentials

## Replace Before Planning

- `backend.tf`: Terraform state backend values
- `variable.tf`: `subscription_id`
- `variable.tf`: `authorized_ip_ranges`
- `variable.tf`: `stage_grouper_postgresql` and `prod_grouper_postgresql` sizing/database defaults
- `local.tf`: CIDRs, if these defaults are not final

## Secrets Note

Grouper PostgreSQL admin passwords are generated with Terraform `random_password` resources. They are not printed in outputs, but they are stored in Terraform state. Treat the configured backend as sensitive.
