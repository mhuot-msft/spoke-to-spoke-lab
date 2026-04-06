<#
.SYNOPSIS
    Post an annotation to the Grafana dashboard.
.PARAMETER Text
    Annotation text (e.g., "Broken: Test Begin")
.PARAMETER Tags
    Comma-separated tags (default: "test")
.PARAMETER TimeMs
    Epoch milliseconds. Defaults to current UTC time.
.EXAMPLE
    .\grafana-annotate.ps1 -Text "Broken: Test Begin" -Tags "test,broken,begin"
    .\grafana-annotate.ps1 -Text "Broken: Test Complete" -Tags "test,broken,end"
#>
param(
    [Parameter(Mandatory)][string]$Text,
    [string]$Tags = "test",
    [long]$TimeMs = 0
)

$ErrorActionPreference = "Stop"

$grafanaUrl = "https://grafana-spoke-lab-fnedazdpcrfec7ah.cus.grafana.azure.com"
$dashboardUID = "spoke-to-spoke-lab"

$token = $env:GRAFANA_TOKEN
if (-not $token) {
    Write-Error "GRAFANA_TOKEN environment variable not set. Create one with:
  az grafana service-account token create -g rg-spoke-to-spoke-lab -n grafana-spoke-lab --service-account annotation-bot --token <name> --time-to-live 30d"
}

if ($TimeMs -eq 0) {
    $TimeMs = [long]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
}

$tagArray = $Tags -split "," | ForEach-Object { $_.Trim() }

$body = @{
    dashboardUID = $dashboardUID
    time         = $TimeMs
    tags         = $tagArray
    text         = $Text
} | ConvertTo-Json -Compress

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}

$resp = Invoke-RestMethod -Uri "$grafanaUrl/api/annotations" -Method POST -Headers $headers -Body $body
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Annotation created (id=$($resp.id)): $Text"
