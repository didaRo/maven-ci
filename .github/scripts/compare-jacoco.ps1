param(
  [Parameter(Mandatory = $true)]
  [string]$CurrentReportPath,

  [string]$BaselineReportPath,

  [double]$MinimumCoveragePercentage = 85.0,
  [double]$MaxDropPercentage = 5.0,

  [switch]$AllowFailure
)

function Get-LineCoveragePercentage([string]$ReportPath) {
  if (-not (Test-Path $ReportPath)) {
    throw "JaCoCo report not found: $ReportPath"
  }

  [xml]$report = Get-Content $ReportPath
  $lineCounter = $report.report.counter | Where-Object { $_.type -eq "LINE" } | Select-Object -First 1

  if (-not $lineCounter) {
    throw "LINE counter not found in JaCoCo report: $ReportPath"
  }

  $missed = [double]$lineCounter.missed
  $covered = [double]$lineCounter.covered
  $total = $missed + $covered

  if ($total -eq 0) {
    return 0.0
  }

  return [Math]::Round(($covered / $total) * 100, 2)
}

$currentCoverage = Get-LineCoveragePercentage -ReportPath $CurrentReportPath
$baselineCoverage = $null
$drop = $null
$failedChecks = @()
$summaryLines = @()

$summaryLines += "## Coverage gate"
$summaryLines += ""
$summaryLines += "- Current line coverage: $currentCoverage%"
$summaryLines += "- Minimum expected line coverage: $MinimumCoveragePercentage%"

if ($currentCoverage -lt $MinimumCoveragePercentage) {
  $failedChecks += "Current line coverage ($currentCoverage%) is below the minimum threshold ($MinimumCoveragePercentage%)."
}

if ($BaselineReportPath -and (Test-Path $BaselineReportPath)) {
  $baselineCoverage = Get-LineCoveragePercentage -ReportPath $BaselineReportPath
  $drop = [Math]::Round($baselineCoverage - $currentCoverage, 2)

  $summaryLines += "- Baseline line coverage: $baselineCoverage%"
  $summaryLines += "- Allowed maximum drop: $MaxDropPercentage%"
  $summaryLines += "- Effective drop: $drop%"

  if ($drop -gt $MaxDropPercentage) {
    $failedChecks += "Coverage degraded by $drop%, which is above the allowed maximum drop of $MaxDropPercentage%."
  }
} else {
  $summaryLines += "- Baseline line coverage: unavailable"
}

if ($failedChecks.Count -gt 0) {
  $summaryLines += ""
  $summaryLines += "Failures:"
  foreach ($failedCheck in $failedChecks) {
    $summaryLines += "- $failedCheck"
  }
} else {
  $summaryLines += ""
  $summaryLines += "Result: coverage gate passed."
}

foreach ($line in $summaryLines) {
  Write-Host $line
}

if ($env:GITHUB_STEP_SUMMARY) {
  Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value $summaryLines
}

if ($failedChecks.Count -gt 0) {
  if ($AllowFailure.IsPresent) {
    Write-Warning "Coverage gate failed but AllowFailure is enabled."
    exit 0
  }

  throw ($failedChecks -join " ")
}
