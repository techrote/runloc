#requires -Version 5.1
[CmdletBinding()]param([Parameter(Mandatory=$true)][string]$CandidateRoot,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{40}$')][string]$CandidateCommit,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{40}$')][string]$ControllerCommit,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{32}$')][string]$ComparisonId,
    [Parameter(Mandatory=$true)][string]$EvidenceParent)
$ErrorActionPreference='Stop';$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
. (Join-Path $PSScriptRoot 'Hosted.Common.ps1')
. (Join-Path $PSScriptRoot 'AssertionControl.Common.ps1')
if($env:GITHUB_REPOSITORY -cne 'techrote/ezvm' -or $env:GITHUB_EVENT_NAME -cne 'workflow_dispatch' -or
    $env:GITHUB_ACTOR -cne 'techrote' -or $env:GITHUB_RUN_ATTEMPT -cne '1' -or
    $env:GITHUB_RUN_ID -cnotmatch '^[1-9][0-9]*$' -or $env:RUNNER_ENVIRONMENT -cne 'github-hosted'){
    throw 'trusted-hosted-negative-control-required'
}
$clock=[Diagnostics.Stopwatch]::StartNew();$started=[DateTime]::UtcNow.ToString('o')
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$controller=Get-PilotSourceIdentity -Root $root -Repository 'https://github.com/techrote/runloc' -ExpectedCommit $ControllerCommit
$candidate=Get-PilotSourceIdentity -Root $CandidateRoot -Repository 'https://github.com/techrote/ezvm' -ExpectedCommit $CandidateCommit
$parent=Assert-PilotPath -Path $EvidenceParent
$lease=New-PilotLease -EvidenceParent $parent -CandidateCommit $CandidateCommit -ControllerCommit $ControllerCommit -WorkParent ([Environment]::GetFolderPath('UserProfile'))
$child=$null;$preflight=$null;$childAttempted=$false;$preflightAttempted=$false;$sourceUnchanged=$false;$removed=$false;$errors=@()
try{
    New-PilotFixture -Lease $lease
    $exe=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $arguments=Get-PilotPowerShellArguments -TargetScript (Join-Path $PSScriptRoot 'Invoke-AclPreflight.ps1') -NamedParameters @{
        SourceRoot=$CandidateRoot;ProbeDirectory=(Join-Path $lease.Private 'acl-probe')}
    $preflightAttempted=$true
    $preflight=Invoke-PilotChild -Executable $exe -Arguments $arguments -WorkingDirectory $CandidateRoot -TemporaryDirectory $lease.Fixture `
        -RawLogPath (Join-Path $lease.Private 'preflight.log') -Clock $clock -ExecutionDeadlineSeconds ($clock.Elapsed.TotalSeconds+60) -CleanupDeadlineSeconds ($clock.Elapsed.TotalSeconds+70)
    if($preflight.exitCode -ne 0 -or -not $preflight.childExited -or $preflight.activeProcesses -ne 0 -or $preflight.forced -or
        $preflight.timedOut -or $preflight.cancelled -or $preflight.outputFailed -or $preflight.outputOverflow -or
        @($preflight.records|Where-Object {$_.Text -ceq 'RUNLOC_EXACT_ACL_PREFLIGHT=PASS'}).Count -ne 1){throw 'assertion-control-preflight-failed'}
    $arguments=Get-PilotPowerShellArguments -TargetScript (Join-Path $PSScriptRoot 'AssertionControl.Workload.ps1') -NamedParameters @{SourceRoot=$CandidateRoot;Fixture=$lease.Fixture}
    $childAttempted=$true
    $child=Invoke-PilotChild -Executable $exe -Arguments $arguments -WorkingDirectory $CandidateRoot -TemporaryDirectory $lease.Fixture `
        -RawLogPath (Join-Path $lease.Private 'assertion-control.log') -Clock $clock -ExecutionDeadlineSeconds ($clock.Elapsed.TotalSeconds+3600) -CleanupDeadlineSeconds ($clock.Elapsed.TotalSeconds+3630)
}catch{$errors+='negative-control-execution-incomplete'}
finally{
    try{
        $after=Get-PilotSourceIdentity -Root $CandidateRoot -Repository 'https://github.com/techrote/ezvm' -ExpectedCommit $CandidateCommit -ExpectedTree $candidate.tree
        $controllerAfter=Get-PilotSourceIdentity -Root $root -Repository 'https://github.com/techrote/runloc' -ExpectedCommit $ControllerCommit -ExpectedTree $controller.tree
        $sourceUnchanged=$after.executedTreeSha256 -ceq $candidate.executedTreeSha256 -and $controllerAfter.executedTreeSha256 -ceq $controller.executedTreeSha256
    }catch{$errors+='source-after-unconfirmed'}
    try{
        $empty=(Test-HostedProcessResolved -Attempted $childAttempted -Result $child) -and (Test-HostedProcessResolved -Attempted $preflightAttempted -Result $preflight)
        if($lease.FixtureCreated){Remove-PilotFixture -Lease $lease -Clock $clock -DeadlineSeconds ($clock.Elapsed.TotalSeconds+180) -OwnedProcessesExited $empty}
        $removed=-not [IO.Directory]::Exists($lease.Fixture)
    }catch{$errors+='negative-control-cleanup-unconfirmed'}
    $lease.Lock.Dispose()
}
$observed=$errors.Count -eq 0 -and (Test-AssertionControlObserved -Child $child -Preflight $preflight -SourceUnchanged $sourceUnchanged -FixtureRemoved $removed)
$receipt=@{schemaVersion=1;issue='CI-POC-003';negativeControlOnly=$true;qualificationPassed=$false;passed=$false;
    control='authenticated-fixed-false-guest-assertion';controlObserved=$observed;comparisonId=$ComparisonId;
    candidate=$candidate;controller=$controller;sourceUnchanged=$sourceUnchanged;startedUtc=$started;endedUtc=[DateTime]::UtcNow.ToString('o');
    elapsedSeconds=$clock.Elapsed.TotalSeconds;repository=$env:GITHUB_REPOSITORY;runId=[long]$env:GITHUB_RUN_ID;runAttempt=1;workflowCommit=$env:GITHUB_SHA;
    runnerEnvironment=$env:RUNNER_ENVIRONMENT;runnerName=$env:RUNNER_NAME;
    requestedAccelerator='tcg';qualificationCpus=6;qualificationMemoryMiB=4096;errors=$errors;exitCode=$(if($null -ne $child){$child.exitCode}else{$null});
    timedOut=$(if($null -ne $child){$child.timedOut}else{$null});cancelled=$(if($null -ne $child){$child.cancelled}else{$null});
    outputFailed=$(if($null -ne $child){$child.outputFailed}else{$null});outputOverflow=$(if($null -ne $child){$child.outputOverflow}else{$null});
    guestAssertionExitCode=$(if($observed){1}else{$null});preflightExitCode=$(if($null -ne $preflight){$preflight.exitCode}else{$null});
    preflightTimedOut=$(if($null -ne $preflight){$preflight.timedOut}else{$null});preflightCancelled=$(if($null -ne $preflight){$preflight.cancelled}else{$null});
    cleanup=@{activeProcesses=$(if($null -ne $child){$child.activeProcesses}else{$null});childExited=$(if($null -ne $child){$child.childExited}else{$false});fixtureRemoved=$removed;
        forced=$(if($null -ne $child){$child.forced}else{$false})}}
$path=Join-Path $parent 'assertion-control-receipt.json'
Write-PilotNewJson -Path $path -Value $receipt
Write-PilotNewJson -Path (Join-Path $parent 'assertion-control-receipt-digest.json') -Value @{schemaVersion=1;file='assertion-control-receipt.json';sha256=(Get-PilotDigest $path)}
# Even an observed intentional failure stays red. No success-eligible path.
exit 1
