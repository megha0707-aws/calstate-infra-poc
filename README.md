# CalState DCS Terraform Infrastructure - Grouper

Terraform template for DCS Grouper AKS `stage` and `prod` clusters in **West US 2**. This infrastructure is intended for Grouper and closely related supporting applications. This repo is code only; nothing has been deployed from it yet.

## Architecture

This template prepares the Azure foundation for Grouper and related DCS applications:

- Resource groups for `stage` and `prod`
- VNets for each environment
- Dedicated `/26` Application Gateway subnets
- Dedicated `/27` PostgreSQL Flexible Server delegated subnets
- Dedicated `/27` AKS node subnets
- AKS clusters using Azure CNI Overlay
- Prod AKS cluster using the `Standard` pricing tier / Stage AKS using the `Free` tier
- `Standard_D4ds_v6` default AKS node pools
- Log Analytics workspaces
- Azure Container Registries
- `AcrPull` role assignments from AKS to ACR

## Network Defaults

```text
stage VNet       = 10.20.0.0/16  Azure network for stage resources
stage AppGW      = 10.20.4.0/26  Dedicated Application Gateway subnet
stage PostgreSQL = 10.20.6.0/27  Delegated PostgreSQL Flexible Server subnet
stage AKS nodes  = 10.20.8.0/27  AKS node subnet
stage pods       = 10.244.0.0/24 AKS overlay pod IP range
stage services   = 10.21.0.0/22  Kubernetes ClusterIP service range

prod VNet        = 10.30.0.0/16  Azure network for prod resources
prod AppGW       = 10.30.4.0/26  Dedicated Application Gateway subnet
prod PostgreSQL  = 10.30.6.0/27  Delegated PostgreSQL Flexible Server subnet
prod AKS nodes   = 10.30.8.0/27  AKS node subnet
prod pods        = 10.245.0.0/24 AKS overlay pod IP range
prod services    = 10.31.0.0/22  Kubernetes ClusterIP service range
```

AKS uses Azure CNI Overlay, so pod IPs come from the overlay pod CIDRs, not from the AKS node subnets.

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

## Not Included Yet

- Application Gateway resource
- PostgreSQL Flexible Server
- PostgreSQL private DNS zone
- Key Vault
- Application Insights
- Workload managed identities
- Kubernetes namespaces, ingress, app manifests, or ArgoCD bootstrap
- Diagnostic settings beyond the Log Analytics workspace

## Replace Before Planning

- `backend.tf`: Terraform state backend values
- `variable.tf`: `subscription_id`
- `variable.tf`: `authorized_ip_ranges`
- `local.tf`: CIDRs, if these defaults are not final
