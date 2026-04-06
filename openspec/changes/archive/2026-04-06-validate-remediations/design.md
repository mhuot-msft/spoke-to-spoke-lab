# Design: Validate Remediations and Produce Report

## Remediation Configurations

### Fix 1: Direct Peering (`bicep/lab-fixed-direct-peering/`)

Self-contained Bicep deployment that modifies the base topology:

- **Adds** direct VNet peering between vnet-spoke-dbrx and vnet-spoke-adls (both directions)
- **Removes** the catch-all UDR (0.0.0.0/0 → VirtualNetworkGateway) from rt-dbrx
- **Disables** "Use Remote Gateway" on spoke peerings since traffic no longer needs gateway transit for spoke-to-spoke
- **Result**: Effective routes show 10.102.0.0/16 with next hop VNetPeering; gateway flows drop to idle

### Fix 2: Adjacent Private Endpoint (`bicep/lab-fixed-adjacent-pe/`)

Self-contained Bicep deployment that adds to the base topology without modifying routing:

- **Adds** subnet-pe-dbrx (10.101.2.0/24) in vnet-spoke-dbrx
- **Deploys** two private endpoints in subnet-pe-dbrx for the ADLS storage account (DFS + Blob sub-resources)
- **Updates** private DNS zone A records to point to the new PE IPs (10.101.2.x instead of 10.102.2.x)
- **Preserves** the catch-all UDR and gateway transit configuration — forced tunneling remains active
- **Result**: /32 InterfaceEndpoint routes for PE IPs override the 0.0.0.0/0 UDR; storage data plane stays in spoke-dbrx; gateway sees only ancillary traffic (AAD auth, DNS)

## Dashboard Improvements

All changes in `dashboards/spoke-to-spoke-lab.json`:

| Change | Before | After | Why |
|--------|--------|-------|-----|
| Storage resource type | `storageAccounts` | `storageAccounts/blobServices/default` | Account-level metrics required PT1H minimum; blobServices supports PT5M |
| Storage time grain | PT1H | PT5M | 15-minute tests invisible with 1-hour aggregation |
| Panel legend | Simple list | Table with min/max/mean calcs | Quantitative comparison across states |
| Gateway Y-axis | Auto-scale | Fixed 0–3500 | Adjacent PE flat line looked volatile with auto-scale |
| Panel height | h=6 | h=8 | Accommodate legend table |
| Annotations | None | Built-in Grafana datasource | Mark test begin/end for precise time correlation |

## Grafana Annotations

- Enabled API keys on Azure Managed Grafana: `az grafana update --api-key Enabled`
- Created service account `annotation-bot` with Editor role
- `scripts/grafana-annotate.ps1` posts annotations via `POST /api/annotations` with dashboard UID, epoch timestamp, tags, and text
- Annotations appear as vertical markers on all panels

## Validation Methodology

### Test Protocol

For each of the 3 states (broken, direct peering, adjacent PE):

1. Deploy/switch to target configuration
2. Verify effective routes on nic-dbrx match expected state
3. Post "Test Begin" annotation to Grafana
4. Run 15 minutes of sustained azcopy traffic (1GB file upload/download loop)
5. Post "Test Complete" annotation
6. Capture Grafana screenshot at 1400×1000 viewport in kiosk mode
7. Record effective route table
8. Wait 5+ minutes between tests for visual separation on dashboard

### Metric Capture

| Metric | Source | Expected Broken | Expected Direct Peering | Expected Adjacent PE |
|--------|--------|----------------|------------------------|---------------------|
| Gateway Flows | VPN Gateway | 601 → 3,120+ | Drops to idle (~600) | Flat at ~600 (ancillary) |
| VM Network Out | VM | Sustained high | Sustained high | Sustained high |
| Storage Ingress | Storage Blob | Sustained high | Sustained high | Sustained high |

### Screenshot Capture

Using Playwright with `--browser=msedge`:
- Navigate to Grafana dashboard with time range parameters (epoch ms) and `?kiosk`
- Viewport: 1400×1000
- Save to `dashboards/{state}.png`

## Security and Compliance Analysis

Added to REPORT.md as a dedicated section analyzing each configuration against:

- **Forced tunneling preservation** — whether the catch-all UDR remains active
- **Central inspection point** — whether the gateway still sees all inter-spoke traffic
- **Data-in-transit security** — all states use Private Link (Azure backbone only)
- **NSG enforcement** — whether NSGs become the primary control (direct peering) or supplementary (adjacent PE)
- **PE surface area** — additional private endpoints to govern in adjacent PE
- **Compliance fit** — which approach requires the least compliance change

## PDF Generation

Python-based pipeline in `scripts/gen-pdf.py`:
1. Python `markdown` module converts REPORT.md → REPORT.html with inline CSS styling
2. Local HTTP server (`python -m http.server 8765`) serves HTML + images
3. Playwright navigates to `http://localhost:8765/REPORT.html` and exports PDF
4. Images use relative paths matching the server root directory structure

## File Structure (New/Modified)

```
bicep/
  lab-fixed-direct-peering/     # Fix 1: complete Bicep deployment
    main.bicep + modules/
  lab-fixed-adjacent-pe/        # Fix 2: complete Bicep deployment
    main.bicep + modules/
dashboards/
  spoke-to-spoke-lab.json       # Updated dashboard definition
  broken.png                    # Grafana screenshot — broken state
  direct-peering.png            # Grafana screenshot — Fix 1
  adjacent-pe.png               # Grafana screenshot — Fix 2
scripts/
  grafana-annotate.ps1          # Annotation helper script
  gen-pdf.py                    # MD → HTML → PDF pipeline
REPORT.md                       # Validation report
REPORT.pdf                      # Generated PDF
README.md                       # Updated with conclusions
```
