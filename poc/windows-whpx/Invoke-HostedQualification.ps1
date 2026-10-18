#requires -Version 5.1
[CmdletBinding()]param(
    [Parameter(Mandatory=$true)][string]$CandidateRoot,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{40}$')][string]$CandidateCommit,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{40}$')][string]$ControllerCommit,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{32}$')][string]$ComparisonId,
    [Parameter(Mandatory=$true)][string]$EvidenceParent
)
$ErrorActionPreference='Stop'
$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
. (Join-Path $PSScriptRoot 'Hosted.Common.ps1')
if($env:GITHUB_REPOSITORY -cne 'techrote/ezvm' -or $env:GITHUB_EVENT_NAME -cne 'workflow_dispatch' -or
    $env:GITHUB_RUN_ATTEMPT -cne '1' -or $env:GITHUB_RUN_ID -cnotmatch '^[1-9][0-9]*$' -or $env:RUNNER_ENVIRONMENT -cne 'github-hosted'){
    throw 'trusted-hosted-first-attempt-required'
}
$clock=[Diagnostics.Stopwatch]::StartNew();$started=[DateTime]::UtcNow.ToString('o')
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$controller=Get-PilotSourceIdentity -Root $root -Repository 'https://github.com/techrote/runloc' -ExpectedCommit $ControllerCommit
$candidate=Get-PilotSourceIdentity -Root $CandidateRoot -Repository 'https://github.com/techrote/ezvm' -ExpectedCommit $CandidateCommit
$os=Get-CimInstance Win32_OperatingSystem
$principal=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
Import-PilotNative
$hostFacts=@{os=$os.Caption;version=$os.Version;build=$os.BuildNumber;powerShell=$PSVersionTable.PSVersion.ToString();
    logicalProcessors=[Environment]::ProcessorCount;availableMemoryBytes=([long]$os.FreePhysicalMemory*1024);
    cpuModels=@(Get-CimInstance Win32_Processor|ForEach-Object {$_.Name.Trim()});
    administrator=$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator);
    seSecurityPrivilegePresent=[RunlocPoc.OwnedProcess]::CurrentTokenHasPrivilege('SeSecurityPrivilege')}
$parent=Assert-PilotPath -Path $EvidenceParent
$lease=New-PilotLease -EvidenceParent $parent -CandidateCommit $CandidateCommit -ControllerCommit $ControllerCommit -WorkParent ([Environment]::GetFolderPath('UserProfile'))
$child=$null;$preflight=$null;$childAttempted=$false;$preflightAttempted=$false;$identities=$null;$sourceUnchanged=$false;$fixtureRemoved=$false;$events=@();$telemetry=$null;$reason='hosted-controller-incomplete'
try {
    New-PilotFixture -Lease $lease
    $exe=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $aclArguments=Get-PilotPowerShellArguments -TargetScript (Join-Path $PSScriptRoot 'Invoke-AclPreflight.ps1') -NamedParameters @{
        SourceRoot=$CandidateRoot;ProbeDirectory=(Join-Path $lease.Private 'acl-probe')}
    $preflightAttempted=$true
    $preflight=Invoke-PilotChild -Executable $exe -Arguments $aclArguments -WorkingDirectory $CandidateRoot -TemporaryDirectory $lease.Fixture `
        -RawLogPath (Join-Path $lease.Private 'preflight.log') -Clock $clock -ExecutionDeadlineSeconds ($clock.Elapsed.TotalSeconds+60) -CleanupDeadlineSeconds ($clock.Elapsed.TotalSeconds+70)
    if($preflight.exitCode -ne 0 -or -not $preflight.childExited -or $preflight.activeProcesses -ne 0 -or $preflight.forced -or
        $preflight.outputFailed -or $preflight.outputOverflow -or @($preflight.records|Where-Object {$_.Text -ceq 'RUNLOC_EXACT_ACL_PREFLIGHT=PASS'}).Count -ne 1){throw 'exact-acl-preflight-failed'}
    $telemetryPath=Join-Path $lease.Private 'telemetry.jsonl'
    $arguments=Get-PilotPowerShellArguments -TargetScript (Join-Path $CandidateRoot 'scripts/Invoke-EzVm010RealPortability.ps1') -NamedParameters @{
        Root=$CandidateRoot;ReleaseQualification=$true;Accelerator='tcg';QualificationCpus=6;TelemetryPath=$telemetryPath}
    $childAttempted=$true
    $child=Invoke-PilotChild -Executable $exe -Arguments $arguments `
        -WorkingDirectory $CandidateRoot -TemporaryDirectory $lease.Fixture -RawLogPath (Join-Path $lease.Private 'harness.log') `
        -Clock $clock -ExecutionDeadlineSeconds ([double]::PositiveInfinity) -CleanupDeadlineSeconds ([double]::PositiveInfinity)
    foreach($record in $child.records){
        # TCG's explicit WHPX SKIP is required evidence here, not the WHPX oracle's failure.
        if($record.Text -cmatch '^EZVM010_WHPX_EXECUTION=SKIP:'){
            $events+=@{kind='capability';name='whpx';value='SKIP';utc=$record.Utc;seconds=($child.startSeconds+$record.Seconds)};continue
        }
        $event=ConvertTo-PilotEvidenceEvent -Line $record.Text -Utc $record.Utc -Seconds ($child.startSeconds+$record.Seconds)
        if($null -ne $event){$events+=,$event}
    }
    $telemetry=Read-PilotTelemetry -Path $telemetryPath -OutputPath (Join-Path $parent 'telemetry-events.json') -Clock $clock -DeadlineSeconds ([double]::PositiveInfinity) -NoOverallTimeout
    $after=Get-PilotSourceIdentity -Root $CandidateRoot -Repository 'https://github.com/techrote/ezvm' -ExpectedCommit $CandidateCommit -ExpectedTree $candidate.tree
    $controllerAfter=Get-PilotSourceIdentity -Root $root -Repository 'https://github.com/techrote/runloc' -ExpectedCommit $ControllerCommit -ExpectedTree $controller.tree
    $sourceUnchanged=$after.executedTreeSha256 -ceq $candidate.executedTreeSha256 -and $controllerAfter.executedTreeSha256 -ceq $controller.executedTreeSha256
    $image=[IO.File]::ReadAllText((Join-Path $CandidateRoot 'manifests/ubuntu-noble-amd64.json'))|ConvertFrom-Json
    $qemu=[IO.File]::ReadAllText((Join-Path $CandidateRoot 'manifests/qemu-windows.json'))|ConvertFrom-Json
    $identities=Get-HostedFixtureIdentity -Lease $lease -Events $events -ExpectedImageSha256 $image.sha256 -ExpectedQemuVersion (Get-PilotExpectedQemuVersion $qemu) -Clock $clock -DeadlineSeconds ([double]::PositiveInfinity) -CandidateRoot $CandidateRoot
    $functional=Test-GateHostedOutcome -Child $child -Events $events -Telemetry $telemetry -SourceUnchanged $sourceUnchanged -Identities $identities
    $reason=if($functional){'complete-functional-scenario'}else{'functional-or-evidence-failure'}
} catch {
    # No arbitrary exception/log/guest text is exported.
    $reason='functional-or-controller-failure'
} finally {
    try {
        $empty=(Test-HostedProcessResolved -Attempted $childAttempted -Result $child) -and
            (Test-HostedProcessResolved -Attempted $preflightAttempted -Result $preflight)
        if($lease.FixtureCreated){Remove-PilotFixture -Lease $lease -Clock $clock -DeadlineSeconds ($clock.Elapsed.TotalSeconds+180) -OwnedProcessesExited $empty}
        $fixtureRemoved=-not [IO.Directory]::Exists($lease.Fixture)
    } catch {$reason='cleanup-failure'}
    $lease.Lock.Dispose()
}
$passed=$reason -ceq 'complete-functional-scenario' -and $fixtureRemoved
$receipt=[ordered]@{schemaVersion=1;issue='CI-POC-003';lane='hosted-tcg';comparisonId=$ComparisonId;
    candidate=$candidate;controller=$controller;repository=$env:GITHUB_REPOSITORY;runId=[long]$env:GITHUB_RUN_ID;
    runAttempt=1;workflowCommit=$env:GITHUB_SHA;runnerEnvironment=$env:RUNNER_ENVIRONMENT;runnerName=$env:RUNNER_NAME;
    requestedAccelerator='tcg';observedAccelerator=$(if($passed){'tcg'}else{''});whpxExecution='SKIP';qualificationCpus=6;
    startedUtc=$started;endedUtc=[DateTime]::UtcNow.ToString('o');elapsedSeconds=$clock.Elapsed.TotalSeconds;
    sourceUnchanged=$sourceUnchanged;passed=$passed;classification=$(if($passed){'pass'}else{'assertion-or-unknown'});reason=$reason;
    preflightExitCode=$(if($null -ne $preflight){$preflight.exitCode}else{$null});
    exitCode=$(if($null -ne $child){$child.exitCode}else{$null});events=$events;telemetry=$telemetry;identities=$identities;
    phaseDurations=(Get-PilotPhaseDurations -Events $events -TotalSeconds $clock.Elapsed.TotalSeconds);
    cleanup=@{childExited=$(if($null -ne $child){$child.childExited}else{$false});activeProcesses=$(if($null -ne $child){$child.activeProcesses}else{$null});
        forced=$(if($null -ne $child){$child.forced}else{$false});fixtureRemoved=$fixtureRemoved};
    host=$hostFacts}
$path=Join-Path $parent 'hosted-receipt.json'
Write-PilotNewJson -Path $path -Value $receipt
Write-PilotNewJson -Path (Join-Path $parent 'hosted-receipt-digest.json') -Value @{schemaVersion=1;file='hosted-receipt.json';sha256=(Get-PilotDigest $path)}
if(-not $passed){exit 1}
exit 0
