#requires -Version 5.1
[CmdletBinding()]param(
    [Parameter(Mandatory=$true)][string]$BackingRoot,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{40}$')][string]$ExpectedControllerCommit,
    [string]$PrivateControllerRoot,
    [ValidateSet('available','hosted-only','loss-before-harness','absent-capacity')][string]$Selection='available',
    [string]$ResumeState
)
$ErrorActionPreference='Stop'
$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
Import-PilotNative
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$identity=Get-PilotSourceIdentity -Root $root -Repository 'https://github.com/techrote/runloc' -ExpectedCommit $ExpectedControllerCommit
$backing=Assert-PilotPath -Path $BackingRoot
$python=(Get-Command python.exe -CommandType Application -ErrorAction Stop|Select-Object -First 1).Source
if($ResumeState){
    $statePath=Assert-PilotPath -Path $ResumeState -File
    $folder=[IO.Path]::GetDirectoryName($statePath)
    if([IO.Path]::GetDirectoryName($folder) -cne $backing -or (Split-Path $folder -Leaf) -cnotmatch '^gate-[a-f0-9]{32}$'){throw 'gate-state-not-owned'}
}else{
    $id=[Guid]::NewGuid().ToString('N')
    $folder=Join-Path $backing ('gate-'+$id)
    [RunlocPoc.OwnedProcess]::CreateNewDirectory($folder)
    Set-PilotPrivateDirectory -Path $folder
    $statePath=Join-Path $folder 'state.json'
    $policy=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'gate-policy.json'))|ConvertFrom-Json
    if($policy.executionApproved -isnot [bool] -or -not $policy.executionApproved){throw 'gate-execution-not-approved'}
    Write-PilotNewJson -Path $statePath -Value @{schemaVersion=1;comparisonId=$id;createdUtc=[DateTime]::UtcNow.ToString('o');
        policy=$policy;policySha256='';candidate=$policy.candidate;gateController=$identity;backingRoot=$backing;
        privateControllerRoot=$PrivateControllerRoot;selection=$Selection}
    & $python -B (Join-Path $PSScriptRoot 'qualification_coordinator.py') --state $statePath --seal-initial-state
    if($LASTEXITCODE -ne 0){throw 'gate-initial-state-invalid'}
}
$planPath=Join-Path $folder ('console-plan-'+[Guid]::NewGuid().ToString('N')+'.json')
Write-PilotNewJson -Path $planPath -Value @{statePath=$statePath;controllerCommit=$ExpectedControllerCommit;python=$python;root=$root}
$hash=Get-PilotDigest -Path $planPath
$arguments=@('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-NoExit','-File',(Join-Path $PSScriptRoot 'Invoke-QualificationConsole.ps1'),'-PlanPath',$planPath,'-PlanSha256',$hash)
$command=(@($arguments|ForEach-Object {[RunlocPoc.OwnedProcess]::QuoteArgument([string]$_)}) -join ' ')
$shell=New-Object -ComObject Shell.Application
$handle=0
$desktop=$shell.Windows().FindWindowSW(0,0,8,[ref]$handle,1)
if($null -eq $desktop){throw 'interactive-explorer-desktop-required'}
$desktop.Document.Application.ShellExecute((Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'),$command,$root,'open',1)
$ready=$planPath+'.ready.json'
$clock=[Diagnostics.Stopwatch]::StartNew()
while(-not [IO.File]::Exists($ready) -and $clock.Elapsed.TotalSeconds -lt 30){Start-Sleep -Milliseconds 200}
if(-not [IO.File]::Exists($ready)){throw 'gate-console-start-unconfirmed-resume-same-state-only'}
$record=[IO.File]::ReadAllText($ready)|ConvertFrom-Json
if($record.parentName -cne 'explorer.exe' -or $record.planSha256 -cne $hash){throw 'gate-console-parent-unconfirmed'}
Write-Output ('RUNLOC_GATE_STATE='+$statePath)
