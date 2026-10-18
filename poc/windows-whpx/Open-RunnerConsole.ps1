#requires -Version 5.1
[CmdletBinding()]param(
    [Parameter(Mandatory=$true)][string]$BackingRoot,
    [ValidateSet('Monitor','Start','Probe')][string]$Mode='Monitor',
    [ValidatePattern('^[a-f0-9]{32}$')][string]$MonitorLeaseId,
    [ValidatePattern('^[a-f0-9]{40}$')][string]$ExpectedControllerCommit,
    [ValidatePattern('^ci-poc-002-[a-f0-9]{40}$')][string]$WorkflowRef,
    [ValidateSet('qualification','probe','no-job')][string]$QualificationMode='qualification'
)
$ErrorActionPreference='Stop'
$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
Import-PilotNative
$backing=Assert-PilotPath -Path $BackingRoot
$controllerRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
if($MonitorLeaseId -and $Mode -cne 'Monitor'){throw 'lease-selection-is-read-only'}
if($MonitorLeaseId){$null=Assert-PilotPath -Path (Join-Path $backing ('runloc-whpx-'+$MonitorLeaseId))}
if ($Mode -ceq 'Start') {
    if (-not $ExpectedControllerCommit -or -not $WorkflowRef) { throw 'reviewed-source-and-workflow-required' }
    $null=Get-PilotSourceIdentity -Root $controllerRoot -Repository 'https://github.com/techrote/runloc' -ExpectedCommit $ExpectedControllerCommit
}
$state=Join-Path $backing ('console-'+[Guid]::NewGuid().ToString('N'))
[RunlocPoc.OwnedProcess]::CreateNewDirectory($state)
Set-PilotPrivateDirectory -Path $state
$planPath=Join-Path $state 'plan.json'
Write-PilotNewJson -Path $planPath -Value @{schemaVersion=1;mode=$Mode;stateRoot=$state;backingRoot=$backing;controllerRoot=$controllerRoot;
    controllerCommit=$ExpectedControllerCommit;workflowRef=$WorkflowRef;qualificationMode=$QualificationMode;monitorLeaseId=$MonitorLeaseId}
$digest=Get-PilotDigest -Path $planPath
$powershell=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
$arguments=@('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass')
if ($Mode -cne 'Probe') { $arguments+='-NoExit' }
$arguments+=@('-File',(Join-Path $PSScriptRoot 'Invoke-RunnerConsole.ps1'),'-PlanPath',$planPath,'-PlanSha256',$digest)
$command=(@($arguments|ForEach-Object {[RunlocPoc.OwnedProcess]::QuoteArgument([string]$_)}) -join ' ')
# Bind to the existing Explorer DESKTOP object. A new Shell.Application's own
# ShellExecute can launch under its caller and would remain coupled to Codex.
$shell=New-Object -ComObject Shell.Application
$windowHandle=0
$desktop=$shell.Windows().FindWindowSW(0,0,8,[ref]$windowHandle,1)
if ($null -eq $desktop) { throw 'interactive-explorer-desktop-required' }
$show=if($Mode -ceq 'Probe'){0}else{1}
$desktop.Document.Application.ShellExecute($powershell,$command,$controllerRoot,'open',$show)
$ready=Join-Path $state 'console-ready.json'
$clock=[Diagnostics.Stopwatch]::StartNew()
while (-not [IO.File]::Exists($ready) -and $clock.Elapsed.TotalSeconds -lt 30) { Start-Sleep -Milliseconds 200 }
if (-not [IO.File]::Exists($ready)) { throw 'independent-console-start-unconfirmed-do-not-replay-start' }
$record=[IO.File]::ReadAllText($ready)|ConvertFrom-Json
if ($record.parentName -cne 'explorer.exe' -or $record.planSha256 -cne $digest) { throw 'independent-console-parent-unconfirmed' }
Write-Output ('RUNLOC_CONSOLE_STATE='+$state)
