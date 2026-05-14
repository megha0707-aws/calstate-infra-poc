# Cal State DCS Terraform Infra

Terraform template for DCS Grouper AKS `stage` and `prod` clusters in **West US 2**. This infrastructure is intended for Grouper and closely related supporting applications. This repo is code only; nothing has been deployed from it yet.

## Architecture

This template prepares the Azure foundation for Grouper and related DCS applications:

- Resource groups for `stage` and `prod`
- VNets for each environment
- Dedicated `/26` Application Gateway subnets
- Dedicated `/27` PostgreSQL Flexible Server delegated subnets
- Dedicated `/27` AKS node subnets
- AKS clusters using Azure CNI Overlay
- `Standard_D4ds_v6` default AKS node pools
- Log Analytics workspaces
- Azure Container Registries
- `AcrPull` role assignments from AKS to ACR

## Network Defaults

```text
stage VNet      = 10.20.0.0/16
stage AppGW     = 10.20.4.0/26
stage PostgreSQL= 10.20.6.0/27
stage AKS nodes = 10.20.8.0/27
stage pods      = 10.244.0.0/24
stage services  = 10.21.0.0/22

prod VNet       = 10.30.0.0/16
prod AppGW      = 10.30.4.0/26
prod PostgreSQL = 10.30.6.0/27
prod AKS nodes  = 10.30.8.0/27
prod pods       = 10.245.0.0/24
prod services   = 10.31.0.0/22
```

AKS uses Azure CNI Overlay, so pod IPs come from the overlay pod CIDRs, not from the AKS node subnets.

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

The diagram also shows components that are not deployed by this template yet:

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
