## 1. New PE Spoke VNet Module

- [x] 1.1 Create `bicep/modules/networking/spoke-pe-vnet.bicep` — Deploy vnet-spoke-pe (10.103.0.0/16) with subnet-pe (10.103.2.0/24). Accept tags parameter. Include SecurityPolicy:ignore tag.
- [x] 1.2 Create `bicep/modules/networking/route-table-pe.bicep` or extend route-tables.bicep — Deploy rt-pe with 0.0.0.0/0 → VirtualNetworkGateway, associate with subnet-pe in vnet-spoke-pe.

## 2. Modify Existing Modules

- [x] 2.1 Update `bicep/modules/networking/spoke-adls-vnet.bicep` — Remove subnet-pe (10.102.2.0/24). The ADLS VNet should only contain subnet-adls (10.102.1.0/24).
- [x] 2.2 Update `bicep/modules/storage/adls-account.bicep` — Change PE deployment target from subnet-pe in spoke-adls to subnet-pe in spoke-pe. Accept the PE subnet resource ID as a parameter instead of assuming it's in the same VNet.
- [x] 2.3 Update `bicep/modules/networking/private-dns-zone.bicep` — Add VNet link for vnet-spoke-pe (4 links total: hub, dbrx, adls, pe).

## 3. Update Broken State Configuration (lab-current)

- [x] 3.1 Update `bicep/lab-current/main.bicep` — Add spoke-pe-vnet module call, add hub↔PE peering (using existing peering.bicep called a third time), add rt-pe, wire PE subnet ID into storage module for PE deployment.
- [x] 3.2 Validate with `az bicep build --file bicep/lab-current/main.bicep` — Ensure no compilation errors.
- [ ] 3.3 Deploy broken state and verify: effective routes on nic-dbrx show 10.103.0.0/16 via VirtualNetworkGateway, DNS resolves to 10.103.2.x, gateway flows increase during traffic test.

## 4. Update Fix 1: Direct Peering Configuration

- [x] 4.1 Update `bicep/lab-fixed-direct-peering/main.bicep` — Change direct peering from DBX↔ADLS to DBX↔PE VNet. Remove catch-all UDR from rt-dbrx. Disable gateway transit on spoke peerings.
- [x] 4.2 Validate with `az bicep build --file bicep/lab-fixed-direct-peering/main.bicep`.
- [ ] 4.3 Deploy and verify: effective routes on nic-dbrx show 10.103.0.0/16 via VNetPeering, gateway flows stay at idle during traffic test.

## 5. Update Fix 2: Adjacent PE Configuration

- [x] 5.1 Update `bicep/lab-fixed-adjacent-pe/main.bicep` — Deploy additional PEs in subnet-pe-dbrx (10.101.2.0/24) in vnet-spoke-dbrx. Update DNS A records to point to DBX-local PE IPs. Keep catch-all UDR and gateway transit active.
- [x] 5.2 Validate with `az bicep build --file bicep/lab-fixed-adjacent-pe/main.bicep`.
- [ ] 5.3 Deploy and verify: effective routes show /32 InterfaceEndpoint routes, gateway flat, storage metrics active.

## 6. Update Report and Documentation

- [ ] 6.1 Update REPORT.md architecture diagrams — Show three-VNet topology (DBX, Hub, PE VNet, ADLS) in all broken/fix diagrams. Update traffic path descriptions.
- [ ] 6.2 Rerun all 3-state validation tests (15 min each) — Capture new screenshots, effective routes, and metric tables with the three-VNet topology.
- [ ] 6.3 Update REPORT.md metrics and screenshots — Replace all test data with new three-VNet results. Update effective route tables.
- [ ] 6.4 Update REPORT.md real-world scenario section — Align the customer context to match the three-VNet topology directly (no longer a "simplification").
- [ ] 6.5 Update README.md — Update architecture description, project structure (new PE VNet module), and getting started instructions.
- [ ] 6.6 Regenerate REPORT.pdf with updated content.

## 7. Update OpenSpec

- [ ] 7.1 Update `openspec/specs/hub-spoke-lab/spec.md` — Apply MODIFIED requirements from delta spec (VNet peering, DNS, direct peering, adjacent PE, report).
- [ ] 7.2 Create `openspec/specs/pe-spoke-vnet/spec.md` — Apply ADDED requirements from new capability spec.
