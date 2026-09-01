<#
.SYNOPSIS
    Automates the RVTools export and executes the VCF 9.1 HCL compatibility analysis.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$vCenterServer,

    [Parameter(Mandatory = $true)]
    [System.Management.Automation.PSCredential]$Credential,

    [string]$OutputDirectory = "C:\VCF_Audits",

    [string]$RvToolsExePath = "C:\Program Files (x86)\Robware\RVTools\RVTools.exe",

    [string]$HclCheckerScript = ".\Test-VCF91HclCompatibility.ps1",

    [string]$TargetRelease = "ESXi 9.1"
)

# 1. Environment & Path Setup
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$exportFileName = "RVTools_Export_$timestamp.xlsx"
$fullExportPath = Join-Path -Path $OutputDirectory -ChildPath $exportFileName
$hclReportPath  = Join-Path -Path $OutputDirectory -ChildPath "VCF91_HCL_Report_$timestamp.csv"

if (-not (Test-Path -Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

if (-not (Test-Path -Path $RvToolsExePath)) {
    throw "RVTools executable not found at '$RvToolsExePath'."
}

if (-not (Test-Path -Path $HclCheckerScript)) {
    throw "HCL validation script not found at '$HclCheckerScript'."
}

# 2. Extract Credentials
$username = $Credential.UserName
$plainPassword = $Credential.GetNetworkCredential().Password

# 3. Execute RVTools CLI Export
Write-Host "Triggering RVTools export for vCenter: $vCenterServer..." -ForegroundColor Cyan

$rvToolsArgs = @(
    "-s", $vCenterServer,
    "-u", $username,
    "-p", $plainPassword,
    "-c", "ExportAll2xlsx",
    "-d", $OutputDirectory,
    "-f", $exportFileName
)

$process = Start-Process -FilePath $RvToolsExePath -ArgumentList $rvToolsArgs -Wait -NoNewWindow -PassThru

if ($process.ExitCode -ne 0 -or (-not (Test-Path -Path $fullExportPath))) {
    throw "RVTools export failed with exit code: $($process.ExitCode)"
}

Write-Host "RVTools export complete: $fullExportPath" -ForegroundColor Green

# 4. Trigger HCL Validation Script
Write-Host "Executing VCF 9.1 Compatibility Assessment..." -ForegroundColor Cyan

$hclParams = @{
    RvToolsPath   = $fullExportPath
    TargetRelease = $TargetRelease
    ExportCsv     = $hclReportPath
}

& $HclCheckerScript @hclParams

Write-Host "Pipeline execution complete. Report generated at: $hclReportPath" -ForegroundColor Green