# Design: Spoke-to-Spoke Lab

## Architecture
Hub-and-spoke with VPN gateway providing route reflector behavior for spoke-to-spoke connectivity. Forced tunneling ensures all traffic routes through the gateway.

## Bicep Module Structure
```
modules/
  networking/
    hub-vnet.bicep          # Hub VNet + GatewaySubnet
    spoke-dbrx-vnet.bicep   # Spoke 1 VNet + subnet + NSG
    spoke-adls-vnet.bicep   # Spoke 2 VNet + subnets
    vpn-gateway.bicep       # VPN Gateway (VpnGw1)
    peering.bicep           # VNet peering with gateway transit
    route-tables.bicep      # UDRs for forced tunneling
    private-dns.bicep       # Private DNS zone + VNet links
  compute/
    vm-dbrx.bicep           # Ubuntu VM + NIC + PIP
  storage/
    adls.bicep              # ADLS Gen2 account
    private-endpoint.bicep  # Private endpoint for dfs
main.bicep                  # Orchestrator
main.bicepparam             # Parameter file
```

## Parameters
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| location | string | resourceGroup().location | Azure region |
| adminUsername | string | azureuser | VM admin username |
| adminPublicKey | string | (required) | SSH public key |
| allowedSshIp | string | (required) | IP for SSH NSG rule |
| storageAccountSuffix | string | (required) | Unique suffix for storage account name |

## Design Decisions
- VPN gateway instead of ER gateway (no circuit needed for lab)
- VpnGw1 SKU is cheapest option that supports gateway transit
- Standard_B2s for the VM to keep costs down
- Hierarchical namespace on storage for ADLS Gen2 compatibility
- Private endpoint for dfs (not blob) to match real Databricks/ADLS pattern
