#requires -Version 5.1
[CmdletBinding()]param([Parameter(Mandatory=$true)][string]$BackingRoot,[Parameter(Mandatory=$true)][string]$CandidateRoot,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{40}$')][string]$CandidateCommit,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{40}$')][string]$ControllerCommit,
    [ValidateSet('basic-clones','release-order','full-forensic')][string]$Scenario='basic-clones')
$ErrorActionPreference='Stop';$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
Import-PilotNative
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$null=Get-PilotSourceIdentity -Root $root -Repository 'https://github.com/techrote/runloc' -ExpectedCommit $ControllerCommit
$null=Get-PilotSourceIdentity -Root $CandidateRoot -Repository 'https://github.com/techrote/ezvm' -ExpectedCommit $CandidateCommit
$backing=Assert-PilotPath -Path $BackingRoot
$folder=Join-Path $backing ('guest-diagnostic-'+[Guid]::NewGuid().ToString('N'))
[RunlocPoc.OwnedProcess]::CreateNewDirectory($folder);Set-PilotPrivateDirectory -Path $folder
$plan=Join-Path $folder 'plan.json'
Write-PilotNewJson -Path $plan -Value @{backingRoot=$backing;candidateRoot=$CandidateRoot;candidateCommit=$CandidateCommit;controllerCommit=$ControllerCommit;stateRoot=$folder;scenario=$Scenario}
$hash=Get-PilotDigest -Path $plan
$arguments=@('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-NoExit','-File',(Join-Path $PSScriptRoot 'Invoke-GuestDiagnostic.ps1'),'-PlanPath',$plan,'-PlanSha256',$hash)
$command=(@($arguments|ForEach-Object {[RunlocPoc.OwnedProcess]::QuoteArgument([string]$_)}) -join ' ')
$shell=New-Object -ComObject Shell.Application;$handle=0
$desktop=$shell.Windows().FindWindowSW(0,0,8,[ref]$handle,1)
if($null -eq $desktop){throw 'interactive-explorer-desktop-required'}
$desktop.Document.Application.ShellExecute((Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'),$command,$root,'open',1)
Write-Output ('RUNLOC_DIAGNOSTIC_STATE='+$folder)
