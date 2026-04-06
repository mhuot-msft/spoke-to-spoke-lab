# Proposal: Validate Remediations and Produce Report

## Intent

The initial lab deployment (2026-04-05) proved that spoke-to-spoke traffic hairpins through the VPN gateway. This follow-up change implements two remediation configurations, validates each with instrumented testing, improves the Grafana dashboard for accurate cross-state comparison, and produces a comprehensive validation report with security/compliance analysis.

## Scope

- **Fix 1 — Direct Peering**: Bicep configuration adding spoke-to-spoke peering and removing forced tunneling UDR
- **Fix 2 — Adjacent Private Endpoint**: Bicep configuration deploying PEs in the consumer spoke to bypass the gateway
- **Dashboard improvements**: Storage metric fix (PT5M on blobServices/default), legend table with min/max/mean, fixed Y-axis 0–3500 on gateway panels, test annotations
- **3-state validation**: Run 15-minute traffic tests in broken, direct peering, and adjacent PE states with screenshots and effective route captures
- **Validation report (REPORT.md)**: Metrics, screenshots, effective routes, analysis of each state
- **Security/compliance analysis**: Forced tunneling, central inspection, NSG, PE surface area implications
- **ER gateway and VWAN notes**: Document equivalence with ExpressRoute gateways and VWAN as untested alternative
- **README update**: Key findings table, report link, ER/VWAN notes

## Out of Scope

- Fix 3 (Specific UDR routes) — evaluated and removed; too brittle for production use
- Azure Virtual WAN deployment — documented as alternative but not tested
- Azure Firewall or NVA deployment — noted as mitigation for direct peering's loss of central inspection
- Automated CI/CD for deployments

## Approach

1. Create self-contained Bicep configurations under `bicep/lab-fixed-direct-peering/` and `bicep/lab-fixed-adjacent-pe/` that duplicate the base modules with targeted changes
2. Fix Grafana dashboard for accurate storage metrics, add legend stats and fixed Y-axis for visual comparison
3. Enable Grafana API keys and create service account for programmatic annotations
4. Run each state for 15 minutes with azcopy traffic, capturing annotations, screenshots, and effective routes
5. Write REPORT.md with correlated metrics, route analysis, and security/compliance comparison table
6. Generate PDF for offline distribution
