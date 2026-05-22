# CalState Grouper AKS Terraform Infrastructure

Terraform infrastructure for dedicated Grouper AKS environments in **West US 2**.
The stack is managed from the `infra/` folder.

## Managed Resources

This stack manages:

- Dev, prod, and shared hub resource groups.
- Dev and prod VNets with dedicated subnets for Application Gateway, PostgreSQL,
  infra hosts, private endpoints, and AKS nodes/pods.
- Shared Grouper AKS hub VNet with `GatewaySubnet` and `AzureBastionSubnet`.
- Hub/spoke VNet peerings between the hub, dev, and prod VNets.
- Optional Azure VPN Gateway S2S resources for Palo Alto IPsec termination.
- PostgreSQL Flexible Servers with private DNS.
- Baseline NSGs for Application Gateway and PostgreSQL subnets.
- AKS clusters using single-subnet Azure CNI flat networking and Cilium.
- Azure Container Registries and AKS `AcrPull` role assignments.
- Log Analytics workspaces.
- Azure Monitor workspaces, Managed Prometheus, and Managed Grafana.
- PostgreSQL secrets in existing Key Vaults.
- Optional VPN pre-shared key in existing Key Vaults.

This stack does **not** currently manage:

- Application Gateway resources.
- Application Gateway public IPs, listeners, routing rules, probes, or TLS
  certificates.
- Azure Bastion host resources.
- Private endpoint resources.
- Storage account resources.
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
registry. ACR private endpoints require the Premium SKU; this stack keeps the
registries on Basic for now, so ACR private endpoint deployment is deferred.

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

All current Azure and Kubernetes service CIDRs are allocated from
`10.247.80.0/20`.

```text
dev VNet address space  = 10.247.80.0/23
dev AppGW subnet        = 10.247.80.0/24
dev PostgreSQL subnet   = 10.247.81.0/27
dev Infra subnet        = 10.247.81.96/27
dev private endpoint    = 10.247.81.64/28
dev AKS subnet          = 10.247.81.128/25
dev services            = 10.247.84.0/24

prod VNet address space = 10.247.82.0/23
prod AppGW subnet       = 10.247.82.0/24
prod PostgreSQL subnet  = 10.247.83.0/27
prod Infra subnet       = 10.247.83.96/27
prod private endpoint   = 10.247.83.64/28
prod AKS subnet         = 10.247.83.128/25
prod services           = 10.247.85.0/24

hub VNet address space  = 10.247.86.0/24
hub GatewaySubnet       = 10.247.86.0/26
hub AzureBastionSubnet  = 10.247.86.64/26

reserved spare space    = 10.247.87.0/24
```

`GatewaySubnet` is reserved for Azure VPN Gateway. Do not attach an NSG to this
subnet. `AzureBastionSubnet` is reserved for future Azure Bastion deployment and
must keep this exact Azure-required subnet name.

AKS uses single-subnet Azure CNI flat networking. AKS nodes and pods consume IPs
from the AKS subnet, so the `/25` AKS subnets intentionally use `max_pods = 20`.
Service CIDRs remain cluster ranges and must not overlap with
campus/on-premises routes, peered VNets, VPN ranges, or other AKS clusters.

## Network Objects

```text
dev VNet                = grouper-dev-tf-vnet
dev AppGW subnet        = grouper-dev-tf-appgw-subnet
dev PostgreSQL subnet   = grouper-dev-tf-psql-subnet
dev Infra subnet        = grouper-dev-tf-infra-subnet
dev Private EP subnet   = grouper-dev-tf-private-endpoint-subnet
dev AKS subnet          = grouper-dev-tf-aks-subnet
dev AppGW NSG           = grouper-dev-appgw-nsg
dev PostgreSQL NSG      = grouper-dev-psql-nsg
dev PostgreSQL DNS zone = grouper-dev.postgres.database.azure.com

prod VNet                = grouper-prod-tf-vnet
prod AppGW subnet        = grouper-prod-tf-appgw-subnet
prod PostgreSQL subnet   = grouper-prod-tf-psql-subnet
prod Infra subnet        = grouper-prod-tf-infra-subnet
prod Private EP subnet   = grouper-prod-tf-private-endpoint-subnet
prod AKS subnet          = grouper-prod-tf-aks-subnet
prod AppGW NSG           = grouper-prod-appgw-nsg
prod PostgreSQL NSG      = grouper-prod-psql-nsg
prod PostgreSQL DNS zone = grouper-prod.postgres.database.azure.com

hub VNet                = grouper-aks-hub-tf-vnet
hub GatewaySubnet       = GatewaySubnet
hub Bastion subnet      = AzureBastionSubnet
```

## Network Security

Application Gateway subnets have dedicated NSGs. Current inbound rules allow:

```text
80/443 from app_gateway_allowed_source_address_prefixes
65200-65535 from GatewayManager
all protocols from AzureLoadBalancer
all other inbound denied
```

PostgreSQL delegated subnets have dedicated NSGs. Current inbound rules allow:

```text
5432 from the matching environment AKS subnet
5432 from the matching PostgreSQL subnet
all other VirtualNetwork inbound denied
```

The AKS, infra, and private endpoint subnets do not currently have NSGs
attached. Add subnet-specific NSGs before placing VMs or other directly managed
compute in the infra subnets. `GatewaySubnet` and `AzureBastionSubnet` do not
have NSGs attached.

## Hybrid Connectivity

The target hybrid pattern is a hub-and-spoke site-to-site VPN. Azure VPN
termination lives only in the shared hub VNet; dev and prod reach on-premises
through VNet peering with gateway transit.

```text
Grouper pods
  -> dev/prod AKS subnet
  -> dev/prod spoke VNet
  -> VNet peering with remote gateway enabled
  -> shared hub VNet GatewaySubnet
  -> Azure VPN Gateway
  -> IPsec/IKEv2 S2S tunnel
  -> on-prem Palo Alto HA pair
  -> on-prem database host/prefixes
```

Current status:

```text
Hub VNet                         = managed by Terraform
Hub GatewaySubnet                = managed by Terraform
Hub/spoke VNet peerings          = managed by Terraform
VPN Gateway resources            = modeled in Terraform, disabled by default
VPN tunnel                       = modeled in Terraform, disabled by default
enable_grouper_aks_s2s_vpn       = false by default
```

Do not create the Virtual Network Gateway manually. The gateway, public IP,
local network gateway, VPN connection, IPsec policy, shared key, and peering
gateway-transit flags are all represented in Terraform. They are created only
when `enable_grouper_aks_s2s_vpn = true`.

## S2S VPN Design

Azure side:

```text
Hub resource group      = Grouper-AKS-Hub
Hub VNet                = grouper-aks-hub-tf-vnet
Hub VNet CIDR           = 10.247.86.0/24
Gateway subnet name     = GatewaySubnet
Gateway subnet CIDR     = 10.247.86.0/26
Gateway type            = Vpn
VPN type                = RouteBased
Gateway SKU             = VpnGw1AZ
Active-active           = false
BGP                     = disabled
Routing model           = static
Connection protocol     = IKEv2
```

On-premises side:

```text
Palo Alto public IP     = 137.145.10.114
On-prem reachable CIDR  = 137.145.22.135/32
```

Azure workload source ranges that the network team should allow and route back:

```text
dev AKS source          = 10.247.81.128/25
prod AKS source         = 10.247.83.128/25
```

With single-subnet Azure CNI flat networking, AKS nodes and pods use IPs from
the AKS subnet. On-prem firewall policy and return routing should therefore use
the AKS subnet CIDRs above.

## VPN Components

When `enable_grouper_aks_s2s_vpn = true`, Terraform creates these resources:

```text
VPN Gateway public IP
  Static Standard public IP in Azure. This is the public Azure endpoint that
  the on-prem Palo Alto connects to.

Azure Virtual Network Gateway
  Azure VPN gateway deployed into the hub VNet GatewaySubnet. This is the Azure
  tunnel endpoint. The subnet must be named exactly GatewaySubnet.

Local Network Gateway
  Azure representation of the on-prem Palo Alto side. It stores the Palo Alto
  public IP and the on-prem address spaces reachable behind the tunnel.

VPN Gateway Connection
  IPsec/IKEv2 connection between the Azure VPN Gateway and Local Network
  Gateway. This object holds the shared key and explicit IPsec policy.

Hub-to-spoke peering gateway transit
  Hub-to-dev and hub-to-prod peerings set allow_gateway_transit = true.

Spoke-to-hub remote gateway use
  Dev-to-hub and prod-to-hub peerings set use_remote_gateways = true.
```

VPN resource names:

```text
name prefix          = AZR-prod-GrouperAKS
VPN gateway          = AZR-prod-GrouperAKS-VNG
VPN gateway PIP      = AZR-prod-GrouperAKS-VNG-PIP
Local network gw     = AZR-prod-GrouperAKS-PaloAlto-LNG
VPN connection       = AZR-prod-GrouperAKS-PaloAlto-CON
IP configuration     = AZR-prod-GrouperAKS-VNG-IPConfig
```

The prefix is controlled by:

```hcl
grouper_aks_connectivity_resource_name_prefix = "AZR-prod-GrouperAKS"
```

## VPN Inputs

The default input values are:

```hcl
enable_grouper_aks_s2s_vpn              = false
onprem_palo_alto_public_ip              = "137.145.10.114"
prod_onprem_database_cidrs              = ["137.145.22.135/32"]
grouper_aks_vpn_gateway_sku             = "VpnGw1AZ"
grouper_aks_s2s_onprem_shared_key       = null
```

Enable the VPN only when the network team is ready for Terraform to create
billable VPN Gateway resources:

```hcl
enable_grouper_aks_s2s_vpn = true
```

The VPN pre-shared key behavior is:

- If `grouper_aks_s2s_onprem_shared_key` is `null`, Terraform generates a
  64-character alphanumeric key.
- If a value is supplied, Terraform uses the supplied key.
- When VPN is enabled, Terraform writes the key to both existing Key Vaults:

```text
kv-dev-grouper  / grouper-aks-s2s-vpn-shared-key
kv-prod-grouper / grouper-aks-s2s-vpn-shared-key
```

Treat Terraform state and saved plan files as sensitive. State will contain the
generated PostgreSQL passwords and, when VPN is enabled, the VPN shared key.

## IPsec Policy

Terraform applies this explicit IPsec policy to the Azure VPN connection:

```text
DH group           = DHGroup14
IKE encryption     = AES256
IKE integrity      = SHA256
IPsec encryption   = AES256
IPsec integrity    = SHA256
PFS group          = PFS14
SA data size       = 102400000 KB
SA lifetime        = 27000 seconds
```

The Palo Alto Phase 1 and Phase 2 settings must match these values.

## Network Team Checklist

Before enabling `enable_grouper_aks_s2s_vpn`, confirm:

- Palo Alto tunnel endpoint public IP is `137.145.10.114`.
- On-prem route/policy should expose `137.145.22.135/32` to Azure.
- On-prem return routing exists for `10.247.81.128/25` and
  `10.247.83.128/25`.
- Palo Alto policies allow the required database/application ports between the
  AKS source subnets and `137.145.22.135/32`.
- Palo Alto IKE/IPsec parameters match the policy above.
- The team is ready for Terraform to create Azure VPN Gateway billing resources.

## AKS

Both clusters use:

```text
network plugin      = azure
network plugin mode = not set
network data plane  = cilium
network policy      = cilium
private API server  = false
OIDC issuer         = true
node public IPs     = false
max pods per node   = 20
```

Default node pools:

```text
dev  node count = 2
dev  VM size    = Standard_D4ads_v5
dev  max pods   = 20
prod node count = 3
prod VM size    = Standard_E4ads_v5
prod max pods   = 20
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

## Private Endpoints

Each environment has a dedicated `/28` private endpoint subnet reserved for
future private access to platform services such as ACR or Storage. Terraform
does not currently create private endpoints. Private endpoint network policies
are disabled on these reserved subnets.

ACR private endpoints are intentionally deferred because the current registries
use the Basic SKU. Upgrade ACR to Premium before adding ACR Private Link.

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
