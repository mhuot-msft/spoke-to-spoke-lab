# Tasks: Deploy Spoke-to-Spoke Lab

## Phase 1: Networking Foundation

- [x] 1.1 Create bicep/modules/networking/hub-vnet.bicep - Deploy vnet-hub (10.100.0.0/16) with GatewaySubnet (10.100.0.0/27)
- [x] 1.2 Create bicep/modules/networking/spoke-dbrx-vnet.bicep - Deploy vnet-spoke-dbrx (10.101.0.0/16) with subnet-dbrx (10.101.1.0/24)
- [x] 1.3 Create bicep/modules/networking/spoke-adls-vnet.bicep - Deploy vnet-spoke-adls (10.102.0.0/16) with subnet-adls (10.102.1.0/24) and subnet-pe (10.102.2.0/24)
- [x] 1.4 Create bicep/modules/networking/vpn-gateway.bicep - Deploy VPN Gateway (VpnGw1 SKU) with public IP in GatewaySubnet. Gateway type Vpn, VPN type RouteBased.
- [x] 1.5 Create bicep/modules/networking/peering.bicep - Reusable module for VNet peering. Accept parameters for local VNet name/ID, remote VNet name/ID, allowGatewayTransit, and useRemoteGateways flags. Call twice from main.bicep (hub-to-dbrx and hub-to-adls).
- [x] 1.6 Create bicep/modules/networking/route-tables.bicep - Deploy rt-dbrx and rt-adls route tables each with a single route: 0.0.0.0/0 next hop VirtualNetworkGateway. Associate rt-dbrx with subnet-dbrx and rt-adls with subnet-adls and subnet-pe.

## Phase 2: DNS and Storage

- [x] 2.1 Create bicep/modules/networking/private-dns-zone.bicep - Deploy private DNS zone privatelink.dfs.core.windows.net. Create VNet links to all three VNets with auto-registration disabled.
- [x] 2.2 Create bicep/modules/storage/adls-account.bicep - Deploy storage account with: kind StorageV2, isHnsEnabled true, publicNetworkAccess Disabled, minimumTlsVersion TLS1_2. Create private endpoint in subnet-pe targeting the dfs sub-resource. Create private DNS zone group linking to the private DNS zone for automatic A record registration.

## Phase 3: Compute

- [x] 3.1 Create bicep/modules/compute/vm-dbrx.bicep - Deploy: pip-dbrx (Standard SKU, static), nsg-dbrx (allow SSH from allowedSshSourceIp parameter only), nic-dbrx (in subnet-dbrx, attach NSG, associate PIP), vm-dbrx (Ubuntu 22.04 LTS, Standard_B2s, SSH key auth, no password).

## Phase 4: Orchestration

- [x] 4.1 Create bicep/main.bicep - Define all parameters (location, adminUsername, adminPublicKey, allowedSshSourceIp, storageAccountSuffix). Call all modules in correct dependency order. Output: VM public IP, storage account name, storage account DFS endpoint.
- [x] 4.2 Create bicepparam file or example deployment command - Include sample az deployment group create command with parameter values.

## Phase 5: Traffic Generation

- [x] 5.1 scripts/traffic-gen.sh exists. Installs azcopy, creates 1GB test file with dd, accepts storage account name and SAS token as arguments, creates loadtest container, loops azcopy upload/download cycles with timestamps. Includes SAS token generation instructions in header comments.

## Phase 6: Dashboard

- [x] 6.1 Grafana dashboard JSON exists at dashboards/spoke-to-spoke-lab.json. Uses Azure Monitor data source with template variables for subscription, resource group, VPN gateway, VM, and storage account.

## Phase 7: Documentation

- [x] 7.1 README.md exists with purpose, architecture diagram, project structure, getting started steps, and validation instructions.
