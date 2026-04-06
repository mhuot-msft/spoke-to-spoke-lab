# Tasks: Validate Remediations and Produce Report

## Phase 1: Remediation Bicep Configurations

- [x] 1.1 Create `bicep/lab-fixed-direct-peering/` — Full Bicep deployment adding spoke-to-spoke peering, removing catch-all UDR, disabling Use Remote Gateway on spoke peerings
- [x] 1.2 Create `bicep/lab-fixed-adjacent-pe/` — Full Bicep deployment adding subnet-pe-dbrx (10.101.2.0/24) with DFS and Blob private endpoints in consumer spoke, updating DNS zone A records
- [x] 1.3 Evaluate and remove Fix 3 (Specific UDR routes) — Determined too brittle for production; deleted `bicep/lab-fixed-udr/` and all references

## Phase 2: Dashboard Improvements

- [x] 2.1 Fix storage panels — Change resource type to `storageAccounts/blobServices/default` with PT5M time grain (was `storageAccounts` with PT1H)
- [x] 2.2 Add legend statistics — Change all 6 panels to table legend with min, max, mean calcs; increase panel height from 6 to 8 grid units
- [x] 2.3 Fix gateway Y-axis — Set fixed scale 0–3500 on both gateway panels for consistent visual comparison across states
- [x] 2.4 Enable Grafana annotations — Add built-in Grafana annotation datasource to dashboard JSON; enable API keys on Managed Grafana instance; create service account `annotation-bot` (Editor role)
- [x] 2.5 Create `scripts/grafana-annotate.ps1` — Helper script for posting test begin/end annotations to Grafana API

## Phase 3: 3-State Validation Testing

- [x] 3.1 Create `testdata` blob container on storage account via ARM API (network rules block CLI access)
- [x] 3.2 Test broken state — Deploy catch-all UDR + gateway transit; run 15-min azcopy traffic (08:05–08:21 CDT); capture screenshot, effective routes, gateway flows (601→3,120)
- [x] 3.3 Test direct peering state — Remove UDR, add spoke-to-spoke peering; run 15-min traffic (08:29–08:44 CDT); capture screenshot, effective routes, gateway flows drop to idle
- [x] 3.4 Test adjacent PE state — Deploy PEs in spoke-dbrx, update DNS; run 15-min traffic (08:54–09:09 CDT); capture screenshot, effective routes, gateway flows flat at ~600 (ancillary)
- [x] 3.5 Restore environment to broken state after testing; recreate DNS A records (PE deletion wipes DNS zone groups)

## Phase 4: Report and Documentation

- [x] 4.1 Write REPORT.md — 3-state comparison with Grafana screenshots, effective route tables, metric summaries, gateway flow analysis
- [x] 4.2 Add security/compliance section — Analyze forced tunneling, central inspection, NSG, PE surface area, compliance fit for each approach with summary comparison table
- [x] 4.3 Add ER gateway equivalence note — Callout that ExpressRoute gateways exhibit same hairpin behavior
- [x] 4.4 Add VWAN alternative section — Document Azure Virtual WAN as untested approach with native spoke-to-spoke routing
- [x] 4.5 Update README.md — Key findings table, ER gateway note, VWAN mention, link to REPORT.md, updated project structure

## Phase 5: PDF Generation

- [x] 5.1 Create `scripts/gen-pdf.py` — Python script converting REPORT.md to REPORT.html with inline CSS
- [x] 5.2 Generate REPORT.pdf — Serve HTML via local HTTP server, export PDF via Playwright (441 KB with embedded images)
