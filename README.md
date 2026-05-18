# CalState Grouper Terraform Infrastructure

Terraform template for dedicated Grouper AKS infrastructure in **West US 2**.
This stack creates two AKS clusters:

- `dev`
- `prod`


Terraform state is stored remotely in Azure Blob Storage.

Terraform lives in the `infra/` folder. Run Terraform commands from there:

```powershell
Set-Location infra
terraform init
terraform plan
```

## Resource Groups

This stack uses one manually bootstrapped resource group for Terraform state and
two Terraform-managed resource groups for the application infrastructure:

```text
Grouper       Terraform state backend resource group
Grouper-Dev   dev AKS, network, PostgreSQL, ACR, Log Analytics, and NSGs
Grouper-Prod  prod AKS, network, PostgreSQL, ACR, Log Analytics, and NSGs
```

The `Grouper` backend resource group, the `groupertfstate` storage account, and
the `terraform` blob container must exist before running `terraform init`.
Terraform will create `Grouper-Dev` and `Grouper-Prod` during the initial apply.
The backend state key is `dcs-apps.tfstate`.

## Architecture

This template prepares the Azure foundation for Grouper:

- Resource groups for `dev` and `prod`
- VNets for each environment
- Dedicated `/26` Application Gateway subnets
- Dedicated `/27` PostgreSQL Flexible Server delegated subnets
- Private Grouper PostgreSQL Flexible Servers with private DNS
- Dedicated AKS node subnets
- Dedicated Grouper AKS clusters using Azure CNI Overlay
- Dev AKS cluster using the `Free` pricing tier
- Prod AKS cluster using the `Standard` pricing tier
- Default AKS node pools only; no separate Grouper user node pools
- Azure CNI powered by Cilium for network policy enforcement
- Log Analytics workspaces
- Azure Container Registries
- `AcrPull` role assignments from AKS to ACR
- Network security groups for Application Gateway and PostgreSQL subnets
- PostgreSQL connection secrets written to manually-created Key Vaults

## Network Defaults

```text
dev VNet        = 10.239.10.0/24   Azure network for dev resources
dev AppGW       = 10.239.10.0/26   Dedicated Application Gateway subnet
dev PostgreSQL  = 10.239.10.64/27  Delegated PostgreSQL Flexible Server subnet
dev AKS nodes   = 10.239.10.96/27  AKS node subnet
dev pods        = 10.239.64.0/21  AKS overlay pod IP range, not an Azure subnet
dev services    = 10.239.11.0/24  Kubernetes ClusterIP service range, not an Azure subnet

prod VNet       = 10.239.20.0/24   Azure network for prod resources
prod AppGW      = 10.239.20.0/26   Dedicated Application Gateway subnet
prod PostgreSQL = 10.239.20.64/27  Delegated PostgreSQL Flexible Server subnet
prod AKS nodes  = 10.239.20.96/27  AKS node subnet
prod pods       = 10.239.72.0/21  AKS overlay pod IP range, not an Azure subnet
prod services   = 10.239.21.0/24  Kubernetes ClusterIP service range, not an Azure subnet
```

AKS uses Azure CNI Overlay, so pod IPs come from the overlay pod CIDRs, not from
the AKS node subnets. Each `/21` overlay pod range leaves room for up to eight
AKS nodes because Azure CNI Overlay allocates pod space to nodes in `/24`
blocks.

Pod and service CIDRs are configured on the AKS clusters but are not created as
Azure VNet subnets. They must still be unique and non-overlapping with the Azure
VNet ranges, on-premises/campus routes, VPN client ranges, peered VNets, and any
network endpoints that Grouper pods need to reach. The Kubernetes DNS service IP
is allocated from the corresponding service CIDR:

```text
dev DNS service IP  = 10.239.11.10
prod DNS service IP = 10.239.21.10
```

The Application Gateway subnets remain `/26` because Azure recommends `/26` as
the minimum Application Gateway subnet size. The PostgreSQL delegated subnets
remain `/27`, while the AKS node subnets are `/27` because these Grouper-only
clusters currently have small node counts and can still grow beyond the initial
dev/prod node defaults.

The network ranges must not overlap with each other, peered VNets, VPN/on-prem
networks, or other AKS clusters.

## Naming

Defaults:

```text
location         = "westus2"
deployment_name  = "grouper"
prefix.dev       = "dev"
prefix.prod      = "prod"
dev RG           = "Grouper-Dev"
prod RG          = "Grouper-Prod"
dev Key Vault    = "kv-dev-grouper"
prod Key Vault   = "kv-prod-grouper"
```

Example names:

```text
Grouper-Dev
grouper-dev-tf-vnet
grouper-dev-tf-appgw-subnet
grouper-dev-tf-psql-subnet
grouper-dev-tf-aks-subnet
aks-grouper-dev-cluster
grouper-dev-law-logs
Grouper-Prod
aks-grouper-prod-cluster
kv-dev-grouper
kv-prod-grouper
```

ACR names cannot contain hyphens and must be globally unique, so they are
generated with stable random suffixes unless `dev_acr_name` or `prod_acr_name`
is set.

## Kubernetes Resources

This Terraform stack does not directly apply Kubernetes namespaces,
deployments, services, ingress objects, or NetworkPolicy resources. Those should
be delivered later by the application deployment workflow, such as Helm, Argo CD,
or another GitOps pipeline.

Because each AKS cluster is dedicated to Grouper, Grouper workloads can run in
the cluster's regular application namespace strategy without this infrastructure
stack creating a separate namespace.

## Network Security

The stack creates baseline subnet NSGs for each environment:

```text
Application Gateway subnet:
  allow inbound TCP 80/443 from app_gateway_allowed_source_address_prefixes
  allow inbound TCP 65200-65535 from GatewayManager for Application Gateway v2
  allow AzureLoadBalancer health traffic
  deny other inbound traffic

PostgreSQL subnet:
  allow inbound TCP 5432 from the environment AKS node subnet
  deny other inbound traffic from the VNet
```

AKS pod-level microsegmentation is expected to use Kubernetes NetworkPolicy or
CiliumNetworkPolicy resources delivered by the application/GitOps workflow. The
AKS clusters are already configured with Azure CNI Overlay and Cilium network
policy support.

NSGs are intentionally used only for coarse subnet boundaries. Avoid adding
strict deny rules to the AKS node subnet until AKS egress is designed with Azure
Firewall or another explicit egress path. AKS node bootstrap, upgrades, image
pulls, control-plane traffic, and Cilium pod networking all depend on required
platform flows that are easier to break than to secure with ad hoc NSG denies.

## Grouper Database

Each environment gets a private PostgreSQL Flexible Server for Grouper:

```text
azurerm_postgresql_flexible_server.dev_grouper
azurerm_postgresql_flexible_server.prod_grouper
```

The PostgreSQL admin passwords are generated by Terraform `random_password`
resources and written to manually-created environment-specific Azure Key Vaults.
The secret values are also stored in Terraform state because Terraform creates
the `azurerm_key_vault_secret` resources.

Key Vault secrets created per environment:

```text
grouper-postgresql-admin-login
grouper-postgresql-admin-password
grouper-postgresql-host
grouper-postgresql-database
```

## Not Included Yet

- Application Gateway resource
- Key Vault resource creation
- Application Insights
- Workload managed identities
- Kubernetes manifests, ingress objects, app services, deployments, or Argo CD bootstrap
- Kubernetes NetworkPolicies
- Diagnostic settings beyond the Log Analytics workspace

## Review Before Planning

Before running `terraform plan`, confirm these deployment-specific values:

```text
backend resource group  = infra/backend.tf
backend storage account = infra/backend.tf
backend blob container  = infra/backend.tf
backend state key       = infra/backend.tf
subscription_id         = infra/variable.tf
dev resource group      = infra/variable.tf
prod resource group     = infra/variable.tf
authorized IP ranges    = infra/variable.tf
App Gateway sources     = infra/variable.tf
Key Vault names         = infra/variable.tf
```

Review PostgreSQL sizing in `infra/variable.tf` before production use. Review
CIDRs in `infra/local.tf` and AKS pod/service CIDRs in `infra/variable.tf`
against campus/on-premises routes, peered VNets, VPN ranges, and other AKS
clusters before applying.

## Secrets Note

Grouper PostgreSQL admin passwords are generated with Terraform
`random_password` resources and written to Key Vault. They are not printed in
outputs, but the secret values are still stored in Terraform state because
Terraform manages the `azurerm_key_vault_secret` resources. The Key Vaults
themselves are created manually outside this Terraform stack. Treat the
configured backend as sensitive.
