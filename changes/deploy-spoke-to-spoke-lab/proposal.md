# Proposal: Deploy Spoke-to-Spoke Lab

## Problem
A customer with a hub-and-spoke topology is seeing their ExpressRoute gateway (Ultra SKU) max out on PPS and throughput. The traffic is Databricks in one spoke hitting ADLS in another spoke, hairpinning through the gateway.

## Objective
Build a reproducible lab environment using Bicep that simulates spoke-to-spoke traffic flowing through a VPN gateway, with full Grafana instrumentation to prove the bottleneck and demonstrate fixes.

## Scope
- Full hub-and-spoke deployment with VPN gateway
- ADLS Gen2 with private endpoint in one spoke
- Linux VM simulating Databricks workload in another spoke
- Forced tunneling to ensure traffic hits the gateway
- Grafana dashboard for before/after comparison
- Traffic generation script

## Approach
Use OpenSpec to define requirements and drive a Bicep expert agent to build modular, parameterized infrastructure-as-code.
