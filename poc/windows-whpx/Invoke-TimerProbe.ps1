#requires -Version 5.1
[CmdletBinding()]param([Parameter(Mandatory=$true)][string]$CandidateRoot,[Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{40}$')][string]$ControllerCommit,[Parameter(Mandatory=$true)][string]$EvidenceParent,[Parameter(Mandatory=$true)][string]$BackingRoot,[switch]$HostedDiagnostic)
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
. (Join-Path $PSScriptRoot 'TimerProbe.Common.ps1')
Import-PilotNative
$principal=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if($HostedDiagnostic){
    if($env:GITHUB_ACTIONS -cne 'true' -or $env:RUNNER_ENVIRONMENT -cne 'github-hosted' -or $env:GITHUB_REPOSITORY -cne 'techrote/ezvm' -or $env:GITHUB_RUN_ID -cnotmatch '^[1-9][0-9]*$' -or $env:GITHUB_EVENT_NAME -cne 'workflow_dispatch' -or $env:GITHUB_ACTOR -cne 'techrote' -or $env:GITHUB_RUN_ATTEMPT -cne '1'){throw 'hosted-timer-diagnostic-environment-required'}
}elseif($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -or [RunlocPoc.OwnedProcess]::CurrentTokenHasPrivilege('SeSecurityPrivilege')){throw 'standard-user-without-security-privilege-required'}
$BackingRoot=Assert-PilotPath -Path $BackingRoot
$sourceRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$controller=Get-PilotSourceIdentity -Root $sourceRoot -Repository 'https://github.com/techrote/runloc' -ExpectedCommit $ControllerCommit
$candidate=Get-PilotSourceIdentity -Root $CandidateRoot -Repository 'https://github.com/techrote/ezvm' -ExpectedCommit '2268468cb3040b9e1dd6deed60d0f13594f768d6' -ExpectedTree 'd5677a166e54583f26e3f08e90e5836c19f99359'
$capacity=[IO.File]::Open((Join-Path $BackingRoot 'runner-capacity.lock'),[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
$clock=[Diagnostics.Stopwatch]::StartNew()
$lease=$null
try{
$lease=New-PilotLease -EvidenceParent $EvidenceParent -CandidateCommit $candidate.commit -ControllerCommit $ControllerCommit -WorkParent ([Environment]::GetFolderPath('UserProfile'))
$child=$null;$preflight=$null;$cases=@();$resolved=$true;$removed=$false;$sourceUnchanged=$false;$failure='';$identities=@{}
try{
    Assert-PilotFixtureSeparation -Fixture $lease.Fixture -ProtectedRoots @($sourceRoot,$CandidateRoot,$BackingRoot)
    New-PilotFixture -Lease $lease
    $exe=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $resolved=$false
    $preflight=Invoke-PilotChild -Executable $exe -Arguments (Get-PilotPowerShellArguments -TargetScript (Join-Path $PSScriptRoot 'Invoke-AclPreflight.ps1') -NamedParameters @{SourceRoot=$CandidateRoot;ProbeDirectory=(Join-Path $lease.Private 'acl-probe')}) -WorkingDirectory $CandidateRoot -TemporaryDirectory $lease.Fixture -RawLogPath (Join-Path $lease.Private 'preflight.log') -Clock $clock -ExecutionDeadlineSeconds ($clock.Elapsed.TotalSeconds+60) -CleanupDeadlineSeconds ($clock.Elapsed.TotalSeconds+70)
    $resolved=$preflight.childExited -and $preflight.activeProcesses -eq 0
    if($preflight.exitCode -ne 0 -or -not $preflight.childExited -or $preflight.activeProcesses -ne 0 -or $preflight.forced -or $preflight.timedOut -or $preflight.cancelled -or $preflight.outputOverflow -or $preflight.outputFailed -or @($preflight.records|Where-Object {$_.Text -ceq 'RUNLOC_EXACT_ACL_PREFLIGHT=PASS'}).Count -ne 1){throw 'timer-probe-preflight-failed'}
    $arguments=Get-PilotPowerShellArguments -TargetScript (Join-Path $PSScriptRoot 'TimerProbe.Workload.ps1') -NamedParameters @{SourceRoot=$CandidateRoot;Fixture=$lease.Fixture;PrivateEvidence=$lease.Private}
    $resolved=$false
    $child=Invoke-PilotChild -Executable $exe -Arguments $arguments -WorkingDirectory $sourceRoot -TemporaryDirectory $lease.Fixture -RawLogPath (Join-Path $lease.Private 'timer-workload.log') -Clock $clock -ExecutionDeadlineSeconds ($clock.Elapsed.TotalSeconds+3600) -CleanupDeadlineSeconds ($clock.Elapsed.TotalSeconds+3630)
    $resolved=$child.childExited -and $child.activeProcesses -eq 0
    $result=[IO.File]::ReadAllText((Join-Path $lease.Private 'timer-workload.json'))|ConvertFrom-Json
    $cases=@($result.cases);$identities=$result.identities
    if($child.exitCode -ne 0 -or -not $resolved -or $child.forced -or $child.timedOut -or $child.cancelled -or $child.outputOverflow -or $child.outputFailed){throw 'timer-workload-incomplete'}
    if($result.failure -or -not $result.processesResolved -or $result.qualificationPassed -or -not $result.diagnosticOnly -or $cases.Count -ne 6){throw 'timer-workload-invalid'}

}catch{$failure='diagnostic-incomplete'}finally{
    try{
    $sourceUnchanged=(Get-PilotSourceIdentity -Root $CandidateRoot -Repository 'https://github.com/techrote/ezvm' -ExpectedCommit $candidate.commit).executedTreeSha256 -ceq $candidate.executedTreeSha256 -and (Get-PilotSourceIdentity -Root $sourceRoot -Repository 'https://github.com/techrote/runloc' -ExpectedCommit $ControllerCommit).executedTreeSha256 -ceq $controller.executedTreeSha256
    }catch{$sourceUnchanged=$false;$failure='diagnostic-source-check-failed'}
    # A reproduced panic retains its owned private fixture for inspection. It is
    # quarantined diagnostic material and must never be reused for qualification.
    if(-not $failure -and $cases.Count -eq 6 -and $lease.FixtureCreated -and $resolved -and @($cases|Where-Object {$_.signals.kernelPanic}).Count -eq 0){
        try{Remove-PilotFixture -Lease $lease -Clock $clock -DeadlineSeconds ($clock.Elapsed.TotalSeconds+120) -OwnedProcessesExited $true;$removed=-not [IO.Directory]::Exists($lease.Fixture)}catch{$failure='diagnostic-fixture-cleanup-failed'}
    }
    try{
    Write-PilotNewJson -Path (Join-Path $lease.Root 'timer-probe-receipt.json') -Value @{schemaVersion=1;hostContext=@{administrator=$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator);seSecurityPrivilegePresent=[RunlocPoc.OwnedProcess]::CurrentTokenHasPrivilege('SeSecurityPrivilege');repository=$env:GITHUB_REPOSITORY;runId=$env:GITHUB_RUN_ID;attempt=$env:GITHUB_RUN_ATTEMPT;event=$env:GITHUB_EVENT_NAME;actor=$env:GITHUB_ACTOR;runnerEnvironment=$env:RUNNER_ENVIRONMENT;workflowCommit=$env:GITHUB_SHA};hostedDiagnostic=[bool]$HostedDiagnostic;diagnosticOnly=$true;qualificationPassed=$false;candidate=$candidate;controller=$controller;elapsedSeconds=$clock.Elapsed.TotalSeconds;cases=$cases;identities=$identities;preflight=$preflight;child=$child;sourceUnchanged=$sourceUnchanged;processesResolved=$resolved;fixtureRemoved=$removed;fixtureQuarantined=(-not $removed);failure=$failure}
    }finally{$lease.Lock.Dispose()}
    Write-Host ('TIMER_PROBE_EVIDENCE='+$lease.Root)
}
}finally{$capacity.Dispose()}
if($failure -or -not $sourceUnchanged -or -not $resolved -or $cases.Count -ne 6){exit 1}
exit 0
