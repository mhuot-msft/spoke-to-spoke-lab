# Spoke-to-Spoke Lab

Azure hub-and-spoke lab environment that demonstrates spoke-to-spoke traffic hairpinning through a VPN gateway.

## Purpose

Reproduces a real-world scenario where Databricks-to-ADLS traffic in a hub-and-spoke topology saturates the gateway (PPS and throughput), with full Grafana instrumentation to prove it.

## Architecture

```mermaid
graph TD
    subgraph hub["Hub VNet (10.0.0.0/16)"]
        vpngw["VPN Gateway\nVpnGw1"]
    end

    subgraph spoke1["Spoke 1 — vnet-spoke-dbrx (10.1.0.0/16)"]
        vm["vm-dbrx\nLinux VM"]
        rt1["rt-dbrx\nUDR"]
    end

    subgraph spoke2["Spoke 2 — vnet-spoke-adls (10.2.0.0/16)"]
        adls["ADLS Gen2\nPrivate Endpoint"]
        rt2["rt-adls\nUDR"]
    end

    spoke1 -- "VNet Peering\n(use gateway transit)" --> hub
    spoke2 -- "VNet Peering\n(use gateway transit)" --> hub

    vm -. "azcopy traffic\nhairpin path" .-> vpngw
    vpngw -. "azcopy traffic\nhairpin path" .-> adls
```

> For the detailed diagram see [diagrams/spoke-to-spoke-lab.excalidraw](diagrams/spoke-to-spoke-lab.excalidraw).

- **Hub VNet** with VPN Gateway (VpnGw1)
- **Spoke 1** (`vnet-spoke-dbrx`, 10.1.0.0/16) — `vm-dbrx` + `rt-dbrx`
- **Spoke 2** (`vnet-spoke-adls`, 10.2.0.0/16) — ADLS Gen2 private endpoint + `rt-adls`
- VNet peering with gateway transit forces spoke-to-spoke through the gateway
- UDRs for forced tunneling

## Project Structure

This project uses [OpenSpec](https://openspec.dev/) to define requirements and drive Bicep development.

- `openspec/` - Project configuration
- `specs/` - Source of truth specifications
- `changes/` - Change proposals, designs, and tasks
- `dashboards/` - Grafana dashboard JSON
- `scripts/` - Traffic generation script
- `diagrams/` - Architecture diagrams

## Getting Started

1. Use an OpenSpec-compatible agent to build the Bicep modules from `changes/deploy-spoke-to-spoke-lab/tasks.md`
2. Deploy with `az deployment group create`
3. Import `dashboards/spoke-to-spoke-lab.json` into Grafana
4. SSH to vm-dbrx and run `scripts/traffic-gen.sh`
5. Watch the gateway metrics in Grafana

## Validation

1. Check effective routes on nic-dbrx: 10.2.0.0/16 should show next hop = VirtualNetworkGateway
2. Run the traffic script and observe gateway PPS/throughput spike
3. Apply fix (direct peering or NVA) and observe gateway metrics drop
