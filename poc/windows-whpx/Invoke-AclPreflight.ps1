#requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$SourceRoot, [Parameter(Mandatory = $true)][string]$ProbeDirectory)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
try {
    Invoke-PilotExactAclPreflight -SourceRoot $SourceRoot -ProbeDirectory $ProbeDirectory
    Write-Output 'RUNLOC_EXACT_ACL_PREFLIGHT=PASS'
    exit 0
}
catch { Write-Error -ErrorRecord $_ -ErrorAction Continue; exit 2 }
