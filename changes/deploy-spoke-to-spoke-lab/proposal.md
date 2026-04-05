# Proposal: Deploy Spoke-to-Spoke Lab

## Intent

A customer's ExpressRoute Ultra gateway is maxing out on PPS and throughput because Databricks-to-ADLS spoke-to-spoke traffic is hairpinning through the gateway. We need a lab environment to reproduce this behavior, prove it with instrumentation, and then demonstrate remediation options.

We're using a VPN gateway instead of ExpressRoute to keep the lab self-contained and avoid circuit dependencies. The routing behavior (gateway transit causing spoke-to-spoke hairpin) is the same.

## Scope

- Hub VNet with VPN gateway (VpnGw1)
- Spoke 1 with a Linux VM simulating a Databricks workload
- Spoke 2 with ADLS Gen2 behind a private endpoint
- VNet peering with gateway transit on both spokes
- UDRs forcing default routes through the gateway
- Private DNS zone for DFS endpoint resolution
- Traffic generation script using azcopy
- Grafana dashboard JSON for Azure Monitor metrics

## Out of Scope

- ExpressRoute circuit or connection (simulated via VPN gateway)
- Actual Databricks workspace deployment
- Remediation deployment (direct spoke peering, NVA/firewall). That would be a follow-up change.
- Azure Managed Grafana deployment (dashboard JSON is provided for import into any Grafana instance)

## Approach

Deploy everything via Bicep, organized into modules by domain. The traffic generation script runs on the VM after deployment. The Grafana dashboard is a standalone JSON file for manual import.

The proof sequence is:
1. Deploy the lab
2. Check effective routes on nic-dbrx to confirm VirtualNetworkGateway next hop for 10.102.0.0/16
3. Run the traffic generation script
4. Observe VPN gateway metrics spiking in Grafana
5. (Future change) Apply remediation and show metrics drop
