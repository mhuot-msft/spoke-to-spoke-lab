# Copilot Instructions — spoke-to-spoke-lab

## Architecture

Azure hub-and-spoke lab that reproduces spoke-to-spoke traffic hairpinning through a VPN gateway. Three VNets in a single resource group (`rg-spoke-to-spoke-lab`):

- **Hub** (`vnet-hub`, 10.100.0.0/16) — VPN Gateway (VpnGw1) in GatewaySubnet
- **Spoke 1** (`vnet-spoke-dbrx`, 10.101.0.0/16) — Ubuntu 22.04 VM simulating Databricks workloads
- **Spoke 2** (`vnet-spoke-adls`, 10.102.0.0/16) — ADLS Gen2 behind a private endpoint (DFS)

VNet peering with gateway transit forces all spoke-to-spoke traffic through the VPN gateway. UDRs on both spokes set 0.0.0.0/0 → VirtualNetworkGateway. A private DNS zone (`privatelink.dfs.core.windows.net`) linked to all three VNets enables private endpoint resolution.

## OpenSpec Workflow

This project uses [OpenSpec](https://openspec.dev/) to define requirements and drive implementation. The workflow is:

1. **Specs** (`openspec/specs/`) — Source-of-truth requirements written as Given/When/Then scenarios
2. **Changes** (`openspec/changes/`) — Proposals, designs, and task breakdowns that implement specs
3. **Skills** (`.github/skills/openspec-*`) — Copilot skills for propose, apply, explore, and archive operations

When implementing Bicep modules, follow the task list in `openspec/changes/deploy-spoke-to-spoke-lab/tasks.md` and the design in `design.md`.

## Bicep Conventions

- Modules organized by domain under `bicep/modules/` — `networking/`, `compute/`, `storage/`, `monitoring/`
- Orchestrated from `bicep/main.bicep` which defines all parameters and calls modules in dependency order
- **Never hardcode** subscription IDs, tenant IDs, or location — always use parameters
- Secrets and SAS tokens must use `@secure()` parameter decorator
- Resource naming: type prefix + functional suffix (e.g., `vnet-hub`, `vm-dbrx`, `pip-dbrx`, `nsg-dbrx`, `sa-adlslab`)
- VPN gateway deployment takes 20–40 minutes; it depends on the hub VNet's GatewaySubnet

## Azure Context

- **Tenant**: Contoso
- **Subscription**: ME-MngEnvMCAP732807-michaelhuot-1 (`7a5070f6-d59a-4d42-b6db-4840a50bf513`)
- **Environment type**: MCAPS Managed Environment — Azure Policy is enforced at the subscription level

### MCAPS Policy Bypass

This subscription has MCAPS policies that block non-compliant resources. To bypass them in this lab, **every resource must include the tag**:

```
SecurityPolicy: ignore
```

In Bicep, apply this consistently via a `tags` variable in `main.bicep` and pass it to all modules:

```bicep
var tags = {
  SecurityPolicy: 'ignore'
}
```

**Key things to watch for:**
- NSGs without certain rules, public IPs, storage accounts with public access disabled, and VMs can all trigger MCAPS deny policies — the tag prevents this
- If a deployment fails with a `RequestDisallowedByPolicy` error, the most likely cause is a missing `SecurityPolicy: ignore` tag on that resource
- Apply the tag to **all** resources, not just the ones that fail — this avoids chasing individual policy violations

## Deployment

```bash
az account set --subscription 7a5070f6-d59a-4d42-b6db-4840a50bf513

az deployment group create \
  --resource-group rg-spoke-to-spoke-lab \
  --template-file bicep/main.bicep \
  --parameters adminUsername=<user> adminPublicKey='<ssh-pub-key>' \
               allowedSshSourceIp=<your-ip> storageAccountSuffix=<unique>
```

## Validation

1. Check effective routes: `az network nic show-effective-route-table --name nic-dbrx --resource-group rg-spoke-to-spoke-lab` — 10.102.0.0/16 should show next hop = VirtualNetworkGateway
2. Run traffic: SSH to vm-dbrx, then `./scripts/traffic-gen.sh <storage_account> <sas_token>`
3. Observe VPN gateway PPS/throughput spike in Grafana dashboard (`dashboards/spoke-to-spoke-lab.json`)
