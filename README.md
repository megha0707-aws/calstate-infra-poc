# CalState Grouper Terraform Infrastructure

Terraform infrastructure for dedicated Grouper AKS environments in **West US 2**.
The stack manages separate `dev` and `prod` Azure foundations from the `infra/`
folder.

## Current Scope

This stack manages:

- Resource groups for dev and prod
- VNets and dedicated subnets for Application Gateway, PostgreSQL, and AKS
- Baseline NSGs for Application Gateway and PostgreSQL subnets
- Private PostgreSQL Flexible Servers with private DNS
- AKS clusters using Azure CNI Overlay and Cilium
- Azure Container Registries with AKS `AcrPull` assignments
- Log Analytics workspaces
- PostgreSQL connection secrets written to manually-managed Key Vaults

These items are intentionally not configured in this Terraform stack yet and
are expected to be added later or managed by a separate application/GitOps
workflow:

- Application Gateway resources
- Key Vault resources
- Application Insights
- Workload identities
- Kubernetes manifests, ingress objects, Argo CD bootstrap, or NetworkPolicies
- AKS diagnostic settings beyond the Log Analytics workspace

## State And Resource Groups

Terraform state is stored remotely in Azure Blob Storage. The backend resources
must exist before running `terraform init`.

```text
Grouper       Terraform state backend resource group
Grouper-Dev   dev infrastructure resource group
Grouper-Prod  prod infrastructure resource group
```

Backend configuration is in `infra/backend.tf`:

```text
resource group  = Grouper
storage account = groupertfstate
container       = terraform
state key       = dcs-apps.tfstate
```

## Core Names

```text
location         = westus2
deployment_name  = grouper
dev RG           = Grouper-Dev
prod RG          = Grouper-Prod
dev AKS          = aks-grouper-dev-cluster
prod AKS         = aks-grouper-prod-cluster
dev Key Vault    = kv-dev-grouper
prod Key Vault   = kv-prod-grouper
```

ACR names are generated with stable random suffixes unless `dev_acr_name` or
`prod_acr_name` is set.

## Network

Each environment has its own VNet and non-overlapping AKS pod/service ranges.
The VNet contains only Azure-routable subnets. AKS pod and service CIDRs are
configured on the cluster, but they are not Azure subnets.

```text
dev VNet        = 10.239.10.0/24
dev AppGW       = 10.239.10.0/26
dev PostgreSQL  = 10.239.10.64/27
dev AKS nodes   = 10.239.10.96/27
dev services    = 10.239.11.0/24
dev pods        = 10.239.64.0/21

prod VNet       = 10.239.20.0/24
prod AppGW      = 10.239.20.0/26
prod PostgreSQL = 10.239.20.64/27
prod AKS nodes  = 10.239.20.96/27
prod services   = 10.239.21.0/24
prod pods       = 10.239.72.0/21
```

Network purpose:

```text
VNet
  Main Azure network boundary for the environment. Azure subnets for AppGW,
  PostgreSQL, and AKS nodes are carved from this range.

Application Gateway subnet
  Reserved for a future Azure Application Gateway. The actual Application
  Gateway resource is not configured yet, but the subnet and NSG are ready.
  This subnet stays dedicated to Application Gateway.

PostgreSQL subnet
  Delegated to Microsoft.DBforPostgreSQL/flexibleServers. PostgreSQL Flexible
  Server uses this subnet for private VNet access. Public PostgreSQL access is
  disabled.

AKS node subnet
  Used by AKS node VMSS instances. Nodes receive IPs from this subnet. The
  subnet has a Microsoft.KeyVault service endpoint for future Key Vault access
  from AKS workloads or add-ons.

Kubernetes service CIDR
  Internal ClusterIP service range used only inside Kubernetes. This is not an
  Azure VNet subnet and should not overlap with any reachable network.

AKS pod CIDR
  Azure CNI Overlay pod address space. Pods receive overlay IPs from this range.
  This is not an Azure VNet subnet and should not overlap with any reachable
  network.
```

AKS uses Azure CNI Overlay, so pod CIDRs are not Azure VNet subnets. Each `/21`
pod range gives room for up to eight nodes because Azure CNI Overlay allocates
pod space to nodes in `/24` blocks.

Before applying, confirm all VNet, pod, and service CIDRs are unique across
campus/on-premises routes, VPN ranges, peered VNets, and other AKS clusters.

## Network Object Names

```text
dev VNet                = grouper-dev-tf-vnet
dev AppGW subnet        = grouper-dev-tf-appgw-subnet
dev PostgreSQL subnet   = grouper-dev-tf-psql-subnet
dev AKS subnet          = grouper-dev-tf-aks-subnet
dev AppGW NSG           = grouper-dev-appgw-nsg
dev PostgreSQL NSG      = grouper-dev-psql-nsg
dev PostgreSQL DNS zone = grouper-dev.postgres.database.azure.com
dev PostgreSQL DNS link = grouper-dev-grouper-psql-dns-link

prod VNet                = grouper-prod-tf-vnet
prod AppGW subnet        = grouper-prod-tf-appgw-subnet
prod PostgreSQL subnet   = grouper-prod-tf-psql-subnet
prod AKS subnet          = grouper-prod-tf-aks-subnet
prod AppGW NSG           = grouper-prod-appgw-nsg
prod PostgreSQL NSG      = grouper-prod-psql-nsg
prod PostgreSQL DNS zone = grouper-prod.postgres.database.azure.com
prod PostgreSQL DNS link = grouper-prod-grouper-psql-dns-link
```

## Network Security

Application Gateway subnet NSGs:

```text
allow inbound TCP 80/443 from app_gateway_allowed_source_address_prefixes
allow inbound TCP 65200-65535 from GatewayManager for Application Gateway v2
allow AzureLoadBalancer health traffic
deny other inbound traffic
```

PostgreSQL subnet NSGs:

```text
allow inbound TCP 5432 from the environment AKS node subnet
deny other inbound traffic from the VNet
```

AKS API access is restricted by `authorized_ip_ranges`. Current allowlists are
defined in `infra/variable.tf`.

NSGs are intentionally used only for coarse subnet boundaries. Pod-level
microsegmentation should be added later with Kubernetes NetworkPolicy or
CiliumNetworkPolicy after the application namespaces and labels are finalized.
Avoid strict deny rules on AKS node subnets until AKS egress is explicitly
designed with Azure Firewall or another egress path.

## AKS

Both clusters use:

```text
network plugin      = azure
network plugin mode = overlay
network data plane  = cilium
network policy      = cilium
private API server  = false
OIDC issuer         = true
node public IPs     = false
```

Current default node pools:

```text
dev  node count = 1
prod node count = 3
VM size         = Standard_D2ads_v5
```

Container Insights is not enabled yet; the `oms_agent` blocks are intentionally
commented out in `infra/aks.tf`.

## PostgreSQL And Key Vault

Each environment gets a private PostgreSQL Flexible Server:

```text
dev  = psql-grouper-dev-grouper
prod = psql-grouper-prod-grouper
```

PostgreSQL public access is disabled. Admin passwords are generated with
Terraform `random_password` resources and written to manually-managed Key Vaults:

```text
dev  = kv-dev-grouper
prod = kv-prod-grouper
```

Terraform writes these secrets to each vault:

```text
grouper-postgresql-admin-login
grouper-postgresql-admin-password
grouper-postgresql-host
grouper-postgresql-database
```

Key Vaults are managed manually outside this Terraform stack. The
Terraform-running identity must have permission to set secrets in both vaults.

Secret values are not printed in outputs, but they are stored in Terraform state
because Terraform manages the `azurerm_key_vault_secret` resources. Treat the
configured backend as sensitive.

## Before Planning

Review these files before running a plan:

```text
infra/backend.tf    backend resource group, storage account, container, state key
infra/variable.tf   subscription ID, resource group names, allowlists, AKS/DB sizing, Key Vault names
infra/local.tf      VNet and subnet CIDRs
```

Also confirm these manual prerequisites:

- Backend resource group, storage account, and blob container exist.
- `kv-dev-grouper` exists in `Grouper-Dev`.
- `kv-prod-grouper` exists in `Grouper-Prod`.
- The Terraform-running identity can write Key Vault secrets.
- Required Azure resource providers are registered because provider auto-registration is disabled.

## Terraform Commands

Run Terraform from the `infra/` folder:

```powershell
Set-Location infra
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

Use this output after apply:

```powershell
terraform output configuration_summary
```
