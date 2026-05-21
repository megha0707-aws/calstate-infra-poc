# CalState Grouper AKS Terraform Infrastructure

Terraform infrastructure for dedicated Grouper AKS environments in **West US 2**.
The stack is managed from the `infra/` folder.

## Managed Resources

This stack manages:

- Dev, prod, and shared hub resource groups.
- Dev and prod VNets with dedicated subnets for Application Gateway, PostgreSQL,
  and AKS nodes.
- Shared Grouper AKS hub VNet with `GatewaySubnet`.
- Hub/spoke VNet peerings between the hub, dev, and prod VNets.
- Optional Azure VPN Gateway S2S resources for Palo Alto IPsec termination.
- PostgreSQL Flexible Servers with private DNS.
- Baseline NSGs for Application Gateway and PostgreSQL subnets.
- AKS clusters using Azure CNI Overlay and Cilium.
- Azure Container Registries and AKS `AcrPull` role assignments.
- Log Analytics workspaces.
- Azure Monitor workspaces, Managed Prometheus, and Managed Grafana.
- PostgreSQL secrets in existing Key Vaults.
- Optional VPN pre-shared key in existing Key Vaults.

This stack does **not** currently manage:

- Application Gateway resources.
- Application Gateway public IPs, listeners, routing rules, probes, or TLS
  certificates.
- Key Vault resources themselves.
- Application Insights.
- Workload identities.
- Kubernetes manifests, ingress resources, Argo CD bootstrap, or NetworkPolicy.
- AKS diagnostic settings and Container Insights log collection.

## Environment Summary

```text
location         = westus2
deployment_name  = grouper

dev RG           = Grouper-Dev
prod RG          = Grouper-Prod
hub RG           = Grouper-AKS-Hub

dev AKS          = aks-grouper-dev-cluster
prod AKS         = aks-grouper-prod-cluster

dev Key Vault    = kv-dev-grouper
prod Key Vault   = kv-prod-grouper

dev ACR          = csugrouperdevacr
prod ACR         = csugrouperprodacr
```

ACR names are globally unique and immutable. Renaming an ACR replaces the
registry.

## Terraform State

Terraform state is stored in Azure Blob Storage:

```text
backend RG       = Grouper
storage account  = groupertfstate
container        = terraform
state key        = dcs-apps.tfstate
```

Treat state and saved plan files as sensitive. State includes generated
PostgreSQL admin passwords. If S2S VPN is enabled, state also includes the VPN
pre-shared key.

## Network Plan

All current Azure, AKS pod, and Kubernetes service CIDRs are allocated from
`10.247.80.0/20`.

```text
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

hub VNet address space  = 10.247.86.0/24
hub GatewaySubnet       = 10.247.86.0/26

reserved spare space    = 10.247.87.0/24
```

`GatewaySubnet` is reserved for Azure VPN Gateway. Do not attach an NSG to this
subnet.

AKS uses Azure CNI Overlay. Pod and service CIDRs are cluster ranges, not Azure
VNet subnets. Confirm these ranges do not overlap with campus/on-premises
routes, peered VNets, VPN ranges, or other AKS clusters before applying.

## Network Objects

```text
dev VNet                = grouper-dev-tf-vnet
dev AppGW subnet        = grouper-dev-tf-appgw-subnet
dev PostgreSQL subnet   = grouper-dev-tf-psql-subnet
dev AKS subnet          = grouper-dev-tf-aks-subnet
dev AppGW NSG           = grouper-dev-appgw-nsg
dev PostgreSQL NSG      = grouper-dev-psql-nsg
dev PostgreSQL DNS zone = grouper-dev.postgres.database.azure.com

prod VNet                = grouper-prod-tf-vnet
prod AppGW subnet        = grouper-prod-tf-appgw-subnet
prod PostgreSQL subnet   = grouper-prod-tf-psql-subnet
prod AKS subnet          = grouper-prod-tf-aks-subnet
prod AppGW NSG           = grouper-prod-appgw-nsg
prod PostgreSQL NSG      = grouper-prod-psql-nsg
prod PostgreSQL DNS zone = grouper-prod.postgres.database.azure.com

hub VNet                = grouper-aks-hub-tf-vnet
hub GatewaySubnet       = GatewaySubnet
```

## Hybrid Connectivity

The target pattern is hub-and-spoke S2S connectivity:

```text
On-premises Palo Alto HA pair
  -> IPsec/IKEv2 site-to-site VPN
  -> shared Grouper AKS hub VNet
  -> hub/spoke VNet peering with gateway transit
  -> dev/prod AKS node subnets
  -> Grouper pods
```

The hub VNet and peerings are managed by default. The VPN Gateway and tunnel are
created only when explicitly enabled. Example `infra/terraform.tfvars` values:

```hcl
enable_grouper_aks_s2s_vpn              = true
onprem_palo_alto_public_ip              = "x.x.x.x"
prod_onprem_database_cidrs              = ["137.145.22.0/24"]

# Optional. Leave null to generate a 64-character PSK.
grouper_aks_s2s_onprem_shared_key       = null
```

Leave `enable_grouper_aks_s2s_vpn` unset, or set it to `false`, if you do not
want Terraform to create billable Azure VPN Gateway resources.

With Azure CNI Overlay, pod egress to on-premises networks is SNATed to AKS node
IPs. Palo Alto policy and on-premises return routing should allow these Azure
source CIDRs:

```text
dev AKS node source  = 10.247.81.32/27
prod AKS node source = 10.247.83.32/27
```

Database ports are not needed to create the VPN tunnel, but they are required
for Palo Alto policy, database firewall policy, and future Azure NSG rules.

## VPN Objects And Inputs

```text
Azure VPN Gateway
  Azure-managed VPN endpoint in the shared hub VNet. This is the Azure side of
  the IPsec tunnel.

VPN Gateway public IP
  Static Azure public IP attached to the Azure VPN Gateway. This is the IP the
  Palo Alto will connect to from on-prem.

Local Network Gateway
  Azure representation of the on-premises Palo Alto side. It stores the Palo
  Alto public IP and the on-prem database CIDRs reachable behind it.

VPN connection
  Azure IPsec connection between the Azure VPN Gateway and Local Network
  Gateway. This is where IKEv2, IPsec policy, and the shared key are applied.
```

Required VPN input values:

```text
enable_grouper_aks_s2s_vpn
  Set to true only when you are ready to create billable Azure VPN Gateway
  resources.

onprem_palo_alto_public_ip
  Public floating IP of the on-prem Palo Alto HA pair used for IPsec
  termination. This is not the database subnet and not an Azure IP.

prod_onprem_database_cidrs
  On-premises database subnet prefixes reachable through the tunnel. Current
  known value: 137.145.22.0/24.

grouper_aks_s2s_onprem_shared_key
  Optional PSK. Leave null to let Terraform generate it and write it to both
  existing Key Vaults.
```

## VPN Gateway Defaults

The shared Grouper AKS VPN Gateway is disabled by default. When enabled,
Terraform uses:

```text
gateway SKU      = VpnGw1AZ
VPN type         = RouteBased
protocol         = IKEv2
routing          = static
BGP              = disabled
active-active    = disabled
public IP SKU    = Standard
public IP zones  = 1, 2, 3
GatewaySubnet    = 10.247.86.0/26
```

Override the SKU only if throughput or connection requirements change:

```hcl
grouper_aks_vpn_gateway_sku = "VpnGw1AZ"
```

## VPN Object Names

VPN resources use the existing Azure inventory style:
`AZR-prod-<Workload>-VNG`.

```text
prefix              = AZR-prod-GrouperAKS
VPN gateway         = AZR-prod-GrouperAKS-VNG
VPN gateway PIP     = AZR-prod-GrouperAKS-VNG-PIP
Palo Alto LNG       = AZR-prod-GrouperAKS-PaloAlto-LNG
VPN connection      = AZR-prod-GrouperAKS-PaloAlto-CON
IP configuration    = AZR-prod-GrouperAKS-VNG-IPConfig
```

The prefix is controlled by:

```hcl
grouper_aks_connectivity_resource_name_prefix = "AZR-prod-GrouperAKS"
```

## VPN Shared Key

When the VPN is enabled, Terraform writes only the VPN pre-shared key to both
existing Key Vaults:

```text
kv-dev-grouper  / grouper-aks-s2s-vpn-shared-key
kv-prod-grouper / grouper-aks-s2s-vpn-shared-key
```

The Terraform variable is:

```hcl
grouper_aks_s2s_onprem_shared_key = null
```

Behavior:

- If the value is `null`, Terraform generates a 64-character alphanumeric PSK.
- If a value is supplied, Terraform uses that supplied PSK.
- Terraform updates the Azure VPN connection shared key and both Key Vault
  secrets.
- Key Vault does not rotate this PSK automatically.
- Non-secret values such as the Azure VPN Gateway public IP, Palo Alto public
  IP, and `prod_onprem_database_cidrs` stay in Terraform configuration,
  Terraform output, and Azure resource properties.

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

AKS API access is restricted by `authorized_ip_ranges`.

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

Terraform writes these PostgreSQL secrets to each existing environment vault:

```text
grouper-postgresql-admin-login
grouper-postgresql-admin-password
grouper-postgresql-host
grouper-postgresql-database
```

The Key Vault resources are manually managed outside this Terraform stack. The
Terraform-running identity must be able to set secrets in both vaults.

## Monitoring

Each environment gets:

```text
Log Analytics workspace
Azure Monitor workspace
Data collection endpoint
Data collection rule for Microsoft-PrometheusMetrics
Data collection rule association to AKS
Data collection endpoint association to AKS
Azure Managed Grafana instance
Monitoring Reader role assignment for Grafana
```

Managed Prometheus is enabled through the AKS `monitor_metrics` block.
Container Insights log collection is not enabled; the `oms_agent` blocks remain
commented out in `infra/aks.tf`.

## Public Ingress Status

The App Gateway subnets and NSGs exist, but Application Gateway itself is not
created yet.

Public HTTPS access to Grouper still requires:

- Application Gateway public IP.
- Application Gateway, preferably WAF_v2 for internet-facing use.
- HTTPS listener on port 443.
- TLS certificate configuration.
- Backend pool, routing rule, and health probe.
- AKS ingress integration.

Expected future path:

```text
Internet / Users
  -> Application Gateway public IP
  -> Application Gateway in the AppGW subnet
  -> private AKS service or ingress endpoint
  -> Grouper pods
```

Application Gateway frontend access is restricted by
`app_gateway_allowed_source_address_prefixes`.

## Before Planning

Confirm these prerequisites:

- Backend resource group, storage account, and blob container exist.
- `kv-dev-grouper` exists in `Grouper-Dev`.
- `kv-prod-grouper` exists in `Grouper-Prod`.
- The Terraform-running identity can write Key Vault secrets.
- Required Azure resource providers are registered because provider
  auto-registration is disabled.
- Before enabling S2S VPN, confirm:
  - Palo Alto floating public IP.
  - Production on-premises database CIDRs.
  - Database ports.
  - Whether Terraform should generate or use a supplied PSK.

Review these files before running a plan:

```text
infra/backend.tf    backend configuration
infra/variable.tf   variables and defaults
infra/local.tf      naming and CIDR allocations
infra/network.tf    VNets, subnets, and peerings
infra/vpn.tf        optional S2S VPN resources
infra/key_vault.tf  Key Vault secret writes
```

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

After apply:

```powershell
terraform output configuration_summary
```
