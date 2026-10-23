#requires -Version 5.1
[CmdletBinding()]param([Parameter(Mandatory=$true)][string]$PlanPath,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{64}$')][string]$PlanSha256)
$ErrorActionPreference='Stop'
$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
$PlanPath=Assert-PilotPath -Path $PlanPath -File
if((Get-PilotDigest -Path $PlanPath) -cne $PlanSha256){throw 'gate-console-plan-changed'}
$plan=[IO.File]::ReadAllText($PlanPath)|ConvertFrom-Json
$state=[IO.File]::ReadAllText((Assert-PilotPath -Path $plan.statePath -File))|ConvertFrom-Json
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
if($root -cne $plan.root -or $state.gateController.commit -cne $plan.controllerCommit){throw 'gate-console-source-binding'}
$null=Get-PilotSourceIdentity -Root $root -Repository 'https://github.com/techrote/runloc' -ExpectedCommit $plan.controllerCommit
$me=Get-CimInstance Win32_Process -Filter ('ProcessId='+$PID)
$parent=Get-CimInstance Win32_Process -Filter ('ProcessId='+$me.ParentProcessId)
if($null -eq $parent -or $parent.Name -cne 'explorer.exe' -or $parent.CreationDate -ge $me.CreationDate){throw 'independent-explorer-parent-required'}
Write-PilotNewJson -Path ($PlanPath+'.ready.json') -Value @{parentName=$parent.Name;parentId=$parent.ProcessId;processId=$PID;planSha256=$PlanSha256}
$Host.UI.RawUI.WindowTitle='CI-PoC003 source gate '+$state.comparisonId
Write-Host 'Explorer-owned independent qualification coordinator. Closing Codex is safe.'
Write-Host 'Keep this console, the private runner console and the PC running.'
Write-Host 'Hosted TCG starts first. Native Windows runner; EzVM WHPX guests use six vCPUs.'
Write-Host ('Private durable state: '+$plan.statePath)
Write-Host 'Heartbeats are observations only; acceptance requires source-bound validated receipts.'
& $plan.python -B -u (Join-Path $PSScriptRoot 'qualification_coordinator.py') --state $plan.statePath 2>&1 | Tee-Object -FilePath ($PlanPath+'.log') -Append
$exit=$LASTEXITCODE
Write-PilotNewJson -Path ($PlanPath+'.ended.json') -Value @{exitCode=$exit;endedUtc=[DateTime]::UtcNow.ToString('o')}
Write-Host ('Coordinator stopped. Actual exit='+$exit+'. See durable state; no further live progress is implied.')
