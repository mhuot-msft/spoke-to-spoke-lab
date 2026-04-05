# Tasks: Deploy Spoke-to-Spoke Lab

## Phase 1: Networking Foundation
- [ ] 1.1 Create hub-vnet.bicep module (vnet-hub, GatewaySubnet)
- [ ] 1.2 Create spoke-dbrx-vnet.bicep module (vnet-spoke-dbrx, subnet-dbrx, nsg-dbrx)
- [ ] 1.3 Create spoke-adls-vnet.bicep module (vnet-spoke-adls, subnet-adls, subnet-pe)

## Phase 2: Gateway
- [ ] 2.1 Create vpn-gateway.bicep module (vpn-gw-hub, VpnGw1 SKU, public IP)

## Phase 3: Connectivity
- [ ] 3.1 Create peering.bicep module (all 4 peering directions with gateway transit)
- [ ] 3.2 Create route-tables.bicep module (rt-dbrx, rt-adls with forced tunnel routes)

## Phase 4: DNS and Storage
- [ ] 4.1 Create private-dns.bicep module (privatelink.dfs.core.windows.net, VNet links)
- [ ] 4.2 Create adls.bicep module (storage account with hierarchical namespace)
- [ ] 4.3 Create private-endpoint.bicep module (PE for dfs in subnet-pe)

## Phase 5: Compute
- [ ] 5.1 Create vm-dbrx.bicep module (Ubuntu 22.04, Standard_B2s, NIC, PIP)

## Phase 6: Orchestration
- [ ] 6.1 Create main.bicep tying all modules together
- [ ] 6.2 Create main.bicepparam with sensible defaults

## Phase 7: Validation
- [ ] 7.1 Wire in Grafana dashboard JSON (already provided in dashboards/)
- [ ] 7.2 Wire in traffic-gen.sh script (already provided in scripts/)
