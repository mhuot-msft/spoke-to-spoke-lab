# Design: Deploy Spoke-to-Spoke Lab

## Architecture Overview

Three VNets in a hub-and-spoke topology, single resource group, single region.

```
                    +-------------------+
                    |     vnet-hub      |
                    |   10.100.0.0/16     |
                    |                   |
                    | +---------------+ |
                    | | GatewaySubnet | |
                    | | 10.100.0.0/27   | |
                    | | vpn-gw-hub    | |
                    | +---------------+ |
                    +--------+----------+
                    /                    \
          peering  /                      \  peering
         (gw transit)                  (gw transit)
                /                          \
  +------------+--------+    +-------------+---------+
  |  vnet-spoke-dbrx     |    |  vnet-spoke-adls       |
  |  10.101.0.0/16         |    |  10.102.0.0/16           |
  |                      |    |                        |
  | +------------------+ |    | +--------------------+ |
  | | subnet-dbrx      | |    | | subnet-adls        | |
  | | 10.101.1.0/24      | |    | | 10.102.1.0/24        | |
  | | vm-dbrx (Ubuntu) | |    | +--------------------+ |
  | +------------------+ |    | +--------------------+ |
  | | rt-dbrx           | |    | | subnet-pe          | |
  | | 0/0 -> VNetGW     | |    | | 10.102.2.0/24        | |
  | +------------------+ |    | | pe-adls (dfs)       | |
  +----------------------+    | +--------------------+ |
                              | | rt-adls             | |
                              | | 0/0 -> VNetGW       | |
                              +------------------------+
```

## Bicep Module Structure

```
bicep/
  main.bicep                    # Orchestrator, parameters, module calls
  modules/
    networking/
      hub-vnet.bicep            # vnet-hub + GatewaySubnet
      spoke-dbrx-vnet.bicep     # vnet-spoke-dbrx + subnet
      spoke-adls-vnet.bicep     # vnet-spoke-adls + subnets (workload + pe)
      peering.bicep             # Reusable peering module (called twice)
      vpn-gateway.bicep         # VPN gateway + public IP
      route-tables.bicep        # UDRs for both spokes
      private-dns-zone.bicep    # privatelink.dfs.core.windows.net + VNet links
    compute/
      vm-dbrx.bicep             # Ubuntu VM + NIC + NSG + public IP
    storage/
      adls-account.bicep        # Storage account (HNS enabled) + private endpoint
scripts/
  traffic-gen.sh                # azcopy traffic generation script (repo root)
dashboards/
  spoke-to-spoke-lab.json       # Grafana dashboard definition (repo root)
```

## Key Design Decisions

### VPN Gateway instead of ExpressRoute

We're using VpnGw1 because it doesn't require an external circuit. The routing behavior with gateway transit is the same. The traffic hairpin pattern is identical. The metrics are different names (Tunnel* vs ExpressRouteGateway*) but the concept maps directly.

### Single resource group

Everything in rg-spoke-to-spoke-lab. This is a lab, easy to tear down with a single `az group delete`.

### Private endpoint for ADLS

The storage account has public access disabled. All traffic goes through the private endpoint in subnet-pe. The private DNS zone ensures vm-dbrx resolves the DFS endpoint to the private IP. This matches the customer's real topology where ADLS is behind a private endpoint.

### UDR design

Both spoke subnets get a route table with 0.0.0.0/0 pointing to VirtualNetworkGateway. This forces all traffic without a more specific route through the VPN gateway, simulating the customer's forced tunneling configuration.

Note: VNet peering routes (10.x.0.0/16 ranges) are system routes that would normally take precedence. The UDRs ensure that even if the system routes are present, the gateway transit peering config is what determines the next hop for spoke-to-spoke traffic.

### azcopy over other tools

azcopy is purpose-built for Azure storage transfers. It handles auth via SAS token, supports large file transfers efficiently, and is easy to script in a loop. This generates realistic storage traffic patterns similar to what Databricks would produce.

### Grafana dashboard as JSON file

Not deploying Azure Managed Grafana in the lab. The dashboard JSON uses template variables so it works with any Grafana instance that has the Azure Monitor data source configured. The customer or SE can import it into their existing Grafana setup.

## Parameters

The main.bicep should accept these parameters:

| Parameter | Type | Description |
|-----------|------|-------------|
| location | string | Azure region (defaults to resource group location) |
| adminUsername | string | SSH username for vm-dbrx |
| adminPublicKey | string | SSH public key for vm-dbrx |
| allowedSshSourceIp | string | Source IP for NSG SSH rule |
| storageAccountSuffix | string | Unique suffix for storage account name |

## Dependencies and Deployment Order

1. VNets (all three, no dependencies on each other)
2. VPN Gateway (depends on hub VNet GatewaySubnet)
3. VNet Peering (depends on VPN Gateway being provisioned, both VNets existing)
4. Route Tables (depends on spoke VNets)
5. Private DNS Zone (depends on all VNets)
6. Storage Account + Private Endpoint (depends on spoke-adls VNet, private DNS zone)
7. VM + NIC + NSG + PIP (depends on spoke-dbrx VNet)

Bicep handles most of this implicitly through resource references, but the VPN gateway is a long deployment (20-40 minutes) so calling that out.
