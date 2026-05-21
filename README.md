# CalState Grouper Terraform Infrastructure

Terraform infrastructure for dedicated Grouper AKS environments in **West US 2**.
The stack manages separate `dev` and `prod` Azure foundations from the `infra/`
folder.

## Managed Scope

This stack currently manages:

- Resource groups for dev and prod.
- VNets and dedicated subnets for Application Gateway, PostgreSQL, and AKS.
- Baseline NSGs for Application Gateway and PostgreSQL subnets.
- Private Azure Database for PostgreSQL Flexible Servers with private DNS.
- AKS clusters using Azure CNI Overlay and Cilium.
- Azure Container Registries with AKS `AcrPull` role assignments.
- Log Analytics workspaces.
- Azure Monitor workspaces, Managed Prometheus collection, and Azure Managed
  Grafana instances for dev and prod.
- PostgreSQL connection secrets written to manually managed Key Vaults.

## Intentional Gaps

These items are not configured in this Terraform stack yet. They are expected to
be added later or managed by a separate application/GitOps workflow:

- Application Gateway resources.
- Application Gateway public IP frontend, listeners, routing rules, probes, and
  TLS certificate configuration.
- Key Vault resources.
- Application Insights.
- Workload identities.
- Kubernetes manifests, ingress objects, Argo CD bootstrap, or NetworkPolicies.
- AKS diagnostic settings and Container Insights log collection beyond the
  existing Log Analytics workspaces.

## Environment Summary

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

ACR names are fixed and must be globally unique across Azure:

```text
dev ACR  = csugrouperdevacr
prod ACR = csugrouperprodacr
```

ACR names are immutable. Changing `dev_acr_name` or `prod_acr_name` later will
replace the registry, so copy or repush required images before applying an ACR
rename.

## Terraform State

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

Treat the backend as sensitive. Terraform state includes generated PostgreSQL
admin passwords because Terraform manages the Key Vault secret resources.

## Tags And Cost Tracking

Terraform applies a consistent tag set to resources that support Azure tags:

```text
ManagedBy    = Terraform
Environment  = dev | prod
Workload     = Grouper-Dev | Grouper-Prod
```

Use `Workload` as the primary grouping tag across inventory, operations, policy,
and cost views:

```text
Workload = Grouper-Dev   dev Grouper environment
Workload = Grouper-Prod  prod Grouper environment
```

The `Workload` value intentionally matches the primary environment resource
group name so reports can group related resources across multiple Azure resource
groups without using a cost-specific tag name. If CSU later provides an official
finance/accounting code, add a separate `CostCenter` tag for that value.

AKS and Azure Monitor create Azure-managed support resource groups:

```text
MC_Grouper-Dev_aks-grouper-dev-cluster_westus2
MC_Grouper-Prod_aks-grouper-prod-cluster_westus2
MA_grouper-dev-monitoring-workspace_westus2_managed
MA_grouper-prod-monitoring-workspace_westus2_managed
```

Those managed groups contain infrastructure such as AKS node VM scale sets,
disks, load balancers, public IPs, and Managed Prometheus backend resources.
Do not delete or manually restructure them. In Cost Management, include both
the `Workload` tag and the related `MC_*` / `MA_*` managed resource groups
when validating full dev or prod cost.

## Network Design

Each environment has its own VNet and non-overlapping AKS pod/service ranges.
The VNet contains only Azure-routable subnets. AKS pod and service CIDRs are
configured on the cluster, but they are not Azure subnets.

```text
assigned network block = 10.247.80.0/20

dev VNet address space  = 10.247.80.0/23
dev AppGW subnet        = 10.247.80.0/24
dev PostgreSQL subnet   = 10.247.81.0/27
dev AKS node subnet     = 10.247.81.32/27
dev services            = 10.247.84.0/24
dev pods                = 10.247.88.0/22

prod VNet address space = 10.247.82.0/23
prod AppGW subnet       = 10.247.82.0/24
prod PostgreSQL subnet  = 10.247.83.0/27
prod AKS node subnet    = 10.247.83.32/27
prod services           = 10.247.85.0/24
prod pods               = 10.247.92.0/22

reserved spare space    = 10.247.86.0/23
```

All VNet subnets, AKS pod CIDRs, and Kubernetes service CIDRs are allocated from
the assigned `10.247.80.0/20` block without overlap. The pod and service ranges
are AKS cluster ranges, not Azure VNet subnets.


### Subnet Purpose

```text
Application Gateway subnet
  Reserved for a future Azure Application Gateway. The actual Application
  Gateway resource is not configured yet, but the subnet and NSG are ready.
  This subnet stays dedicated to Application Gateway.

  The original architecture diagram showed an App Gateway subnet size of /26.
  This repo intentionally uses /24 instead because Azure recommends /24 for
  Application Gateway v2 and WAF_v2 subnets to provide autoscale and maintenance
  headroom. The AppGW /24 is carved from the environment VNet address space and
  remains dedicated to Application Gateway.

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

AKS uses Azure CNI Overlay. Each node gets a fixed `/24` pod block from the
cluster pod CIDR. The `/22` pod ranges provide four `/24` node blocks per
environment, which covers prod's three-node pool plus one surge node during
upgrades.

Before applying, confirm all VNet, pod, and service CIDRs are unique across
campus/on-premises routes, VPN ranges, peered VNets, and other AKS clusters.

## Network Objects

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

## Public Ingress Status

Azure subnets are private address ranges inside a VNet. The App Gateway subnet
is the correct landing zone for public ingress, but the subnet itself does not
make the application public.

Public HTTPS access to Grouper still requires:

- Public IP resource for the Application Gateway frontend.
- Azure Application Gateway resource, preferably WAF_v2 for internet-facing use.
- HTTPS listener on port 443.
- TLS certificate configuration, likely from Key Vault.
- Backend pool, routing rule, and health probe targeting the AKS-hosted Grouper
  service or ingress endpoint.
- AKS ingress integration, such as Application Gateway Ingress Controller,
  Application Gateway for Containers, or another agreed ingress pattern.

Expected public request path after those pieces are added:

```text
Internet / Users
  -> Application Gateway public IP
  -> Application Gateway in the AppGW subnet
  -> private AKS service or ingress endpoint
  -> Grouper pods
```

## Network Security

Application Gateway subnet NSGs:

```text
Allow-Frontend-Http-Https-Inbound
  priority    = 100
  source      = app_gateway_allowed_source_address_prefixes
  destination = AppGW subnet CIDR
  ports       = TCP 80, 443
  purpose     = allow approved users or networks to reach future HTTP/HTTPS
                Application Gateway listeners

Allow-GatewayManager-Inbound
  priority    = 110
  source      = GatewayManager service tag
  destination = AppGW subnet CIDR
  ports       = TCP 65200-65535
  purpose     = allow Azure Application Gateway v2 platform management traffic

Allow-AzureLoadBalancer-Inbound
  priority    = 120
  source      = AzureLoadBalancer service tag
  destination = AppGW subnet CIDR
  ports       = any
  purpose     = allow Azure load balancer health/platform traffic

Deny-All-Inbound
  priority    = 4096
  source      = any
  destination = AppGW subnet CIDR
  ports       = any
  purpose     = block all other inbound traffic to the AppGW subnet
```

PostgreSQL subnet NSGs:

```text
Allow-AKS-PostgreSQL-Inbound
  priority    = 100
  source      = environment AKS node subnet CIDR
  destination = PostgreSQL subnet CIDR
  ports       = TCP 5432
  purpose     = allow Grouper workloads on AKS nodes to reach PostgreSQL

Allow-PostgreSQL-Subnet-Inbound
  priority    = 110
  source      = PostgreSQL subnet CIDR
  destination = PostgreSQL subnet CIDR
  ports       = TCP 5432
  purpose     = allow PostgreSQL Flexible Server intra-subnet database traffic

Deny-VNet-Inbound
  priority    = 4096
  source      = VirtualNetwork service tag
  destination = PostgreSQL subnet CIDR
  ports       = any
  purpose     = block other inbound VNet traffic from reaching PostgreSQL
```

AKS API access is restricted by `authorized_ip_ranges`. Application Gateway
frontend access is restricted by `app_gateway_allowed_source_address_prefixes`.


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

Default node pools:

```text
dev  node count = 1
dev  VM size    = Standard_D4ads_v5
prod node count = 3
prod VM size    = Standard_E4ads_v5
```

Dev uses a smaller general-purpose node to control cost while still providing
more headroom than the original `Standard_D2ads_v5`. Prod uses memory-optimized
`Standard_E4ads_v5` nodes for a standard Grouper deployment because Grouper's
published baseline guidance calls for enough room for the daemon, UI, and web
services containers.

Container Insights is not enabled yet; the `oms_agent` blocks are intentionally
commented out in `infra/aks.tf`.

## Monitoring And Grafana

The monitoring stack follows the Azure Managed Prometheus and Azure Managed
Grafana pattern used in `calstate-co/calstate-ai-tf-infra`, scoped to this
repo's `dev` and `prod` environments.

Each environment gets:

```text
Azure Monitor workspace
Data collection endpoint
Data collection rule for Microsoft-PrometheusMetrics
Data collection rule association to the AKS cluster
Data collection endpoint association to the AKS cluster
Azure Managed Grafana instance
Monitoring Reader role assignment for Grafana on the Monitor workspace
```

AKS Managed Prometheus is enabled with the `monitor_metrics` block on both AKS
clusters. Azure Managed Grafana is integrated directly with the environment's
Azure Monitor workspace.

Current monitoring resources:

```text
dev Monitor workspace  = grouper-dev-monitoring-workspace
dev Grafana            = grouper-dev-grafana

prod Monitor workspace = grouper-prod-monitoring-workspace
prod Grafana           = grouper-prod-grafana
```

This enables Kubernetes metrics collection for Grafana without turning on
Container Insights log ingestion. Log Analytics workspaces still exist for each
environment, but the `oms_agent` blocks remain commented out to avoid unexpected
Log Analytics ingestion cost.

## PostgreSQL And Key Vault

Each environment gets a private PostgreSQL Flexible Server:

```text
dev  = psql-grouper-dev-grouper
prod = psql-grouper-prod-grouper
```

Current PostgreSQL defaults:

```text
dev  version = 17
dev  SKU     = B_Standard_B1ms

prod version = 17
prod SKU     = GP_Standard_D2ds_v5
```

PostgreSQL public access is disabled. Admin passwords are generated with
Terraform `random_password` resources and written to manually managed Key
Vaults:

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

## Before Planning

Review these files before running a plan:

```text
infra/backend.tf    backend resource group, storage account, container, state key
infra/variable.tf   subscription ID, resource group names, allowlists, AKS/DB sizing, Key Vault names
infra/local.tf      VNet and subnet CIDRs
```

Confirm these manual prerequisites:

- Backend resource group, storage account, and blob container exist.
- `kv-dev-grouper` exists in `Grouper-Dev`.
- `kv-prod-grouper` exists in `Grouper-Prod`.
- The Terraform-running identity can write Key Vault secrets.
- Required Azure resource providers are registered because provider
  auto-registration is disabled.

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
