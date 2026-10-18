#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet('Start', 'Status', 'Stop', 'Reconcile')][string]$Action,
    [string]$BackingRoot = '', [string]$LeaseRoot = '',
    [ValidatePattern('^[a-f0-9]{40}$')][string]$ExpectedControllerCommit,
    [ValidateSet('qualification', 'probe', 'no-job')][string]$Mode = 'qualification',
    [ValidateRange(30, 1800)][int]$QueueSeconds = 600,
    [ValidatePattern('^ci-poc-002-[a-f0-9]{40}$')][string]$WorkflowRef
)
$ErrorActionPreference = 'Stop'
. ([IO.Path]::Combine($PSScriptRoot, 'Pilot.Bootstrap.ps1'))
if (-not (Test-PilotEarlyDedicatedFileInvocation -CommandLine ([Environment]::GetCommandLineArgs()) -ExpectedScript $PSCommandPath -InvocationName $MyInvocation.InvocationName)) {
    throw 'Launch a dedicated powershell.exe -NoProfile -NonInteractive -File Invoke-OneJobRunner.ps1 process.'
}
$env:PSModulePath = [IO.Path]::Combine($PSHOME, 'Modules')
. (Join-Path $PSScriptRoot 'Runner.Common.ps1')

function Write-RunnerEvent {
    param([string]$Kind, [object]$Data)
    $script:eventNumber++
    Write-PilotNewJson -Path (Join-Path $script:lease.Root ('event-{0:d6}.json' -f $script:eventNumber)) -Value @{
        schemaVersion = 1; leaseId = $script:lease.Id; utc = [DateTime]::UtcNow.ToString('o'); kind = $Kind; data = $Data }
}

if ($Action -ne 'Start') {
    $root = Assert-PilotPath -Path $LeaseRoot
    $ownerPath = Assert-PilotPath -Path (Join-Path $root 'lease.json') -File
    $owner = [IO.File]::ReadAllText($ownerPath) | ConvertFrom-Json
    if ($owner.root -cne $root -or (Split-Path $root -Leaf) -cne ('runloc-whpx-' + $owner.leaseId)) { throw 'runner-lease-mismatch' }
    $intent = [IO.File]::ReadAllText((Assert-PilotPath -Path (Join-Path $root 'runner-intent.json') -File)) | ConvertFrom-Json
    if ($intent.name -cne ('runloc-' + $owner.leaseId) -or $intent.ownerDigest -cne (Get-PilotDigest -Path $ownerPath)) { throw 'runner-lease-mismatch' }
    if ($Action -eq 'Status') {
        Get-ChildItem -LiteralPath $root -Filter 'event-*.json' -File | Sort-Object Name | ForEach-Object { [IO.File]::ReadAllText($_.FullName) }
        exit 0
    }
    if ($Action -eq 'Stop') {
        Write-PilotNewJson -Path (Join-Path $root 'stop.request') -Value @{ leaseId = $owner.leaseId; requestedUtc = [DateTime]::UtcNow.ToString('o') }
        exit 0
    }
    $lock = [IO.File]::Open((Join-Path $root 'active.lock'), [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try {
        $remote = Get-RunnerByName -Name $intent.name
        if ($null -ne $remote) { $null = Remove-RunnerRegistration -Name $intent.name -RunnerId $remote.id }
        # A dead supervisor has lost its native Job handle. Do not infer owned
        # process/storage disposal from a numeric PID or delete a retained disk.
        Write-PilotNewJson -Path (Join-Path $root ('reconcile-' + [Guid]::NewGuid().ToString('N') + '.json')) -Value @{
            schemaVersion = 1; leaseId = $owner.leaseId; registrationAbsent = $true; localState = 'retain-for-owned-process-and-fixture-audit'; replayAllowed = $false }
    }
    finally { $lock.Dispose() }
    exit 0
}

if (-not $ExpectedControllerCommit -or -not $WorkflowRef) { throw 'reviewed-controller-commit-and-workflow-tag-required' }
if (-not $script:PilotWindows -or -not [Environment]::Is64BitProcess) { throw 'windows-x64-required' }
Import-PilotNative
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -or [RunlocPoc.OwnedProcess]::CurrentTokenHasPrivilege('SeSecurityPrivilege')) { throw 'standard-user-without-security-privilege-required' }
$controllerRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$source = Get-PilotSourceIdentity -Root $controllerRoot -Repository 'https://github.com/techrote/runloc' -ExpectedCommit $ExpectedControllerCommit
$backing = Assert-PilotPath -Path $BackingRoot
Assert-PilotFixtureSeparation -Fixture $backing -ProtectedRoots @($controllerRoot)
$workflowPinPath = Assert-PilotPath -Path (Join-Path $PSScriptRoot 'runner-workflow.json') -File
$workflowPin = [IO.File]::ReadAllText($workflowPinPath) | ConvertFrom-Json
if ($workflowPin.repository -cne 'techrote/ezvm' -or $workflowPin.path -cne '.github/workflows/ezvm-ci-poc-002.yml' -or
    $workflowPin.sha256Lf -cnotmatch '^[a-f0-9]{64}$' -or
    $workflowPin.workflowCommit -cnotmatch '^[a-f0-9]{40}$') { throw 'approved-workflow-pin-required' }
$commitResponse = Invoke-RunnerApi -Endpoint ('repos/techrote/ezvm/commits/' + [Uri]::EscapeDataString($WorkflowRef))
if ($commitResponse.Status -ne 200 -or $commitResponse.Data.sha -cne $WorkflowRef.Substring('ci-poc-002-'.Length) -or
    $commitResponse.Data.sha -cne $workflowPin.workflowCommit) { throw 'workflow-tag-commit-mismatch' }
$workflowCommit = $commitResponse.Data.sha
$workflowResponse = Invoke-RunnerApi -Endpoint ('repos/techrote/ezvm/contents/' + $workflowPin.path + '?ref=' + $workflowCommit)
if ($workflowResponse.Status -ne 200 -or $workflowResponse.Data.encoding -cne 'base64') { throw 'workflow-definition-unavailable' }
$workflowText = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($workflowResponse.Data.content)).Replace("`r`n", "`n")
$sha = [Security.Cryptography.SHA256]::Create()
try { $workflowHash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($workflowText)))).Replace('-', '').ToLowerInvariant() }
finally { $sha.Dispose() }
if ($workflowHash -cne $workflowPin.sha256Lf) { throw 'workflow-definition-not-approved' }
$backingLock = [IO.File]::Open((Join-Path $backing 'runner-capacity.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
$archive = Get-RunnerPinnedArchive -BackingRoot $backing
$pin = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'runner.json')) | ConvertFrom-Json
$candidate = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'candidate.json')) | ConvertFrom-Json
$script:lease = New-PilotLease -EvidenceParent $backing -CandidateCommit $candidate.commit -ControllerCommit $ExpectedControllerCommit -WorkParent ([Environment]::GetFolderPath('UserProfile'))
$script:eventNumber = 0
$name = 'runloc-' + $lease.Id
$job = $null; $runnerId = 0; $runId = 0; $forced = $false; $remoteAbsent = $false; $exited = $true; $active = 0
$dispatchAttempted = $false
$workflowCleanupConfirmed = $false
$clock = [Diagnostics.Stopwatch]::StartNew(); $reason = 'startup-failed'; $success = $false; $fixtureRemoved = $false
$jobStarted = $false
$completedObservedAt = $null
$sentinelPath = Join-Path $backing ('sentinel-' + $lease.Id + '.txt')
Write-PilotNewJson -Path $sentinelPath -Value @{ leaseId = $lease.Id; purpose = 'unrelated-to-job-fixture' }
$sentinelHash = Get-PilotDigest -Path $sentinelPath
try {
    Write-PilotNewJson -Path (Join-Path $lease.Root 'runner-intent.json') -Value @{
        schemaVersion = 1; name = $name; ownerDigest = $lease.OwnerDigest; mode = $Mode; repository = 'techrote/ezvm';
        source = $source; workflowCommit = $workflowCommit; workflowSha256Lf = $workflowHash; candidateCommit = $candidate.commit;
        backingArchiveSha256 = $pin.sha256; overallTimeoutDisabled = $true; qualificationCpus = 8 }
    Write-Host ('RUNLOC_RUNNER_LEASE=' + $lease.Root)
    New-PilotFixture -Lease $lease
    $runnerDirectory = Join-Path $lease.Fixture 'runner'
    Expand-Archive -LiteralPath $archive -DestinationPath $runnerDirectory -ErrorAction Stop
    $listener = Assert-PilotPath -Path (Join-Path $runnerDirectory 'bin/Runner.Listener.exe') -File
    $exited = $false; $active = $null
    $versionResult = Invoke-PilotChild -Executable $listener -Arguments @('--version') -WorkingDirectory $runnerDirectory -TemporaryDirectory $lease.Fixture `
        -RawLogPath (Join-Path $lease.Private 'version.log') -Clock $clock -ExecutionDeadlineSeconds ($clock.Elapsed.TotalSeconds + 30) -CleanupDeadlineSeconds ($clock.Elapsed.TotalSeconds + 40)
    $exited = $versionResult.childExited; $active = $versionResult.activeProcesses
    if ($versionResult.exitCode -ne 0 -or $versionResult.forced -or @($versionResult.records | Where-Object { $_.Text -ceq $pin.version }).Count -ne 1) { throw 'runner-version-mismatch' }
    Write-RunnerEvent -Kind 'registration-intent' -Data @{ name = $name }
    $registration = New-RunnerRegistration -Name $name
    $runnerId = [long]$registration.runner.id
    Write-RunnerEvent -Kind 'registered' -Data @{ runnerId = $runnerId; name = $name }
    Assert-RunnerRouting -Runner $registration.runner -Name $name
    $jit = ConvertTo-RunnerPinnedJitConfig -Encoded $registration.encoded_jit_config -RunnerId $runnerId -Name $name
    $exited = $false; $active = $null
    $job = New-Object RunlocPoc.OwnedProcess($listener, [string[]]@('run', '--once'), $runnerDirectory, $lease.Fixture,
        (Join-Path $lease.Private 'runner.log'), [long]33554432, $jit)
    $jit = $null
    $registration = $null
    Write-RunnerEvent -Kind 'listener-started' -Data @{ processId = $job.ProcessId; createdUtc = $job.CreatedUtc; executableSha256 = (Get-PilotDigest -Path $listener) }
    $online = $false
    while (-not $job.HasExited) {
        $null = $job.Drain()
        if ($job.OutputFailed -or $job.OutputOverflow) { throw 'runner-output-incomplete' }
        if ([IO.File]::Exists((Join-Path $lease.Root 'stop.request'))) { throw 'owner-cancelled' }
        $observed = Get-RunnerByName -Name $name
        if ($null -ne $observed -and $observed.id -ne $runnerId) { throw 'runner-identity-changed' }
        if ($null -ne $observed) { Assert-RunnerRouting -Runner $observed -Name $name }
        if (-not $online -and $null -ne $observed -and $observed.status -ceq 'online') {
            $online = $true
            Write-RunnerEvent -Kind 'online' -Data @{ runnerId = $runnerId }
            if ($Mode -ne 'no-job') {
                Write-RunnerEvent -Kind 'dispatch-intent' -Data @{ workflowCommit = $workflowCommit; comparisonId = $lease.Id }
                $dispatchAttempted = $true
                $dispatch = Invoke-RunnerApi -Method POST -Endpoint 'repos/techrote/ezvm/actions/workflows/ezvm-ci-poc-002.yml/dispatches' -Body @{
                    ref = $WorkflowRef; return_run_details = $true; inputs = @{ runner_name = $name; comparison_id = $lease.Id; mode = $Mode } }
                if ($dispatch.Status -ne 200 -or $dispatch.Data.workflow_run_id -le 0) { throw 'dispatch-unconfirmed-do-not-replay' }
                $runId = [long]$dispatch.Data.workflow_run_id
                Write-RunnerEvent -Kind 'dispatched' -Data @{ comparisonId = $lease.Id; runId = $runId }
            }
        }
        if ($Mode -ne 'no-job' -and $online) {
            $runs = Invoke-RunnerApi -Endpoint ('repos/techrote/ezvm/actions/workflows/ezvm-ci-poc-002.yml/runs?event=workflow_dispatch&per_page=100')
            if ($runs.Status -ne 200) { throw 'workflow-state-unknown' }
            $matching = @($runs.Data.workflow_runs | Where-Object { $_.display_title -ceq ('CI-PoC002 ' + $lease.Id) -and $_.head_sha -ceq $workflowCommit })
            if ($matching.Count -gt 1) { throw 'duplicate-workflow-attempt' }
            if ($matching.Count -eq 1) {
                if ($runId -eq 0) { $runId = [long]$matching[0].id; Write-RunnerEvent -Kind 'run-associated' -Data @{ runId = $runId; runnerId = $runnerId } }
                $associated = Get-RunnerAssociatedJob -RunId $runId -RunnerId $runnerId -WorkflowCommit $workflowCommit -ComparisonId $lease.Id
                $assigned = @(); if ($null -ne $associated) { $assigned = @($associated) }
                if ($assigned.Count -eq 1) { $jobStarted = $true }
                if ($assigned.Count -eq 1 -and $assigned[0].status -ceq 'completed') {
                    if ($null -eq $completedObservedAt) { $completedObservedAt = $clock.Elapsed.TotalSeconds }
                    Write-RunnerEvent -Kind 'job-completed' -Data @{ runId = $runId; jobId = $assigned[0].id; runnerId = $runnerId; conclusion = $assigned[0].conclusion }
                    $success = $assigned[0].conclusion -ceq 'success'
                }
            }
        }
        if (Test-RunnerQueueExpired -ElapsedSeconds $clock.Elapsed.TotalSeconds -QueueSeconds $QueueSeconds -ApprovedJobStarted $jobStarted) { throw 'no-job-deadline' }
        if ($null -ne $completedObservedAt -and $clock.Elapsed.TotalSeconds - $completedObservedAt -ge 60) { throw 'listener-exit-deadline' }
        Start-Sleep -Seconds 5
    }
    # Listener exit can precede the REST job conclusion. Resolve that race with
    # bounded observation; it never starts another registration or job.
    $resultClock = [Diagnostics.Stopwatch]::StartNew()
    while (-not $success -and $runId -gt 0 -and $resultClock.Elapsed.TotalSeconds -lt 60) {
        $associated = Get-RunnerAssociatedJob -RunId $runId -RunnerId $runnerId -WorkflowCommit $workflowCommit -ComparisonId $lease.Id
        $assigned = @(); if ($null -ne $associated -and $associated.status -ceq 'completed') { $assigned = @($associated) }
        if ($assigned.Count -eq 1) {
            Write-RunnerEvent -Kind 'job-completed-final' -Data @{ runId = $runId; jobId = $assigned[0].id; runnerId = $runnerId; conclusion = $assigned[0].conclusion }
            $success = $assigned[0].conclusion -ceq 'success'
            break
        }
        Start-Sleep -Seconds 5
    }
    $reason = if ($success) { 'job-completed' } else { 'listener-exited-without-accepted-job' }
}
catch {
    $success = $false
    # Keep only the bounded, fixed vocabulary. Never stringify API/JIT errors.
    $reason = if ($_.Exception.Message -cmatch '^[a-z][a-z0-9-]{0,100}$') { $_.Exception.Message } else { 'runner-operation-failed' }
}
finally {
    try { if ($null -ne $job) {
        if (-not $job.HasExited -or $job.ActiveProcesses -ne 0) { $forced = $true; $job.Terminate() }
        $stopClock = [Diagnostics.Stopwatch]::StartNew()
        while ((-not $job.HasExited -or $job.ActiveProcesses -ne 0) -and $stopClock.Elapsed.TotalSeconds -lt 30) { Start-Sleep -Milliseconds 100 }
        $exited = $job.HasExited; $active = $job.ActiveProcesses
        $listenerExit = if ($exited) { $job.ExitCode } else { $null }
        $outputComplete = $job.FinishOutput(3000) -and -not $job.OutputOverflow -and -not $job.OutputFailed
        Write-RunnerEvent -Kind 'listener-ended' -Data @{ exited = $exited; activeProcesses = $active; exitCode = $listenerExit; forced = $forced; outputComplete = $outputComplete }
        if ($listenerExit -ne 0 -or -not $outputComplete) { $success = $false }
    } }
    catch { $reason = 'listener-cleanup-unconfirmed'; $success = $false }
    finally { if ($null -ne $job) { try { $job.Dispose() } catch { $success = $false; $exited = $false } } }
    try {
        if ($dispatchAttempted -and $runId -eq 0) {
            $runs = Invoke-RunnerApi -Endpoint 'repos/techrote/ezvm/actions/workflows/ezvm-ci-poc-002.yml/runs?event=workflow_dispatch&per_page=100'
            if ($runs.Status -ne 200) { throw 'dispatch-state-unknown' }
            $matching = @($runs.Data.workflow_runs | Where-Object { $_.display_title -ceq ('CI-PoC002 ' + $lease.Id) -and $_.head_sha -ceq $workflowCommit })
            if ($matching.Count -ne 1) { throw 'dispatch-state-unknown' }
            $runId = [long]$matching[0].id
        }
        if ($runId -gt 0 -and -not $success) {
            $cancel = Invoke-RunnerApi -Method POST -Endpoint ('repos/techrote/ezvm/actions/runs/' + $runId + '/cancel')
            if ($cancel.Status -ne 202 -and $cancel.Status -ne 409) { throw 'workflow-cancellation-unconfirmed' }
        }
        if ($runId -gt 0) {
            $workflowClock = [Diagnostics.Stopwatch]::StartNew()
            do {
                $runState = Invoke-RunnerApi -Endpoint ('repos/techrote/ezvm/actions/runs/' + $runId)
                if ($runState.Status -ne 200 -or $runState.Data.head_sha -cne $workflowCommit -or $runState.Data.display_title -cne ('CI-PoC002 ' + $lease.Id)) { throw 'workflow-cleanup-identity-unknown' }
                $workflowCleanupConfirmed = $runState.Data.status -ceq 'completed'
                if (-not $workflowCleanupConfirmed) { Start-Sleep -Seconds 5 }
            } while (-not $workflowCleanupConfirmed -and $workflowClock.Elapsed.TotalSeconds -lt 60)
            if (-not $workflowCleanupConfirmed) { throw 'workflow-cleanup-unconfirmed' }
        }
        elseif (-not $dispatchAttempted) { $workflowCleanupConfirmed = $true }
    }
    catch { $reason = 'workflow-cleanup-unconfirmed'; $success = $false }
    try {
        if ($runnerId -gt 0) { $remoteAbsent = Remove-RunnerRegistration -Name $name -RunnerId $runnerId }
        else { $remoteAbsent = $null -eq (Get-RunnerByName -Name $name) }
        Write-RunnerEvent -Kind 'registration-absent' -Data @{ runnerId = $runnerId; absent = $remoteAbsent }
    }
    catch { $reason = 'remote-cleanup-unconfirmed'; $success = $false }
    try {
        if (-not $exited -or $active -ne 0) { throw 'runner-process-state-unresolved' }
        Remove-RunnerNestedFixtures -Lease $lease -ExpectedJobControllerCommit $workflowPin.jobControllerCommit -ExpectedCandidateCommit $candidate.commit -Clock $clock -OwnedProcessesExited ($exited -and $active -eq 0)
        Remove-PilotFixture -Lease $lease -Clock $clock -DeadlineSeconds ($clock.Elapsed.TotalSeconds + 180) -OwnedProcessesExited ($exited -and $active -eq 0)
        $fixtureRemoved = -not [IO.Directory]::Exists($lease.Fixture)
    }
    catch { $reason = 'owned-job-material-quarantined'; $success = $false }
    $success = $success -and $exited -and $active -eq 0 -and -not $forced -and $remoteAbsent -and $fixtureRemoved
    $backingIntact = $false; $sentinelIntact = $false; $sourceIntact = $false
    try {
        $backingIntact = [IO.File]::Exists($archive) -and (Get-PilotDigest -Path $archive) -ceq $pin.sha256
        $sentinelIntact = (Get-PilotDigest -Path $sentinelPath) -ceq $sentinelHash
        $after = Get-PilotSourceIdentity -Root $controllerRoot -Repository 'https://github.com/techrote/runloc' -ExpectedCommit $ExpectedControllerCommit
        $sourceIntact = $source.executedTreeSha256 -ceq $after.executedTreeSha256
    }
    catch { $reason = 'backing-sentinel-or-controller-unverifiable'; $success = $false }
    $success = Test-RunnerFinalOutcome -JobPassed $success -Reason $reason -Exited $exited -ActiveProcesses $active -Forced $forced `
        -RemoteAbsent $remoteAbsent -FixtureRemoved $fixtureRemoved -BackingIntact $backingIntact -SentinelIntact $sentinelIntact -SourceIntact $sourceIntact -WorkflowCleanupConfirmed $workflowCleanupConfirmed
    try { Write-RunnerEvent -Kind 'final' -Data @{ passed = $success; reason = $reason; runnerId = $runnerId; runId = $runId;
        activeProcesses = $active; fixtureRemoved = $fixtureRemoved; registrationAbsent = $remoteAbsent;
        elapsedSeconds = $clock.Elapsed.TotalSeconds; reusableBackingPreserved = $backingIntact; unrelatedSentinelSurvived = $sentinelIntact; controllerUnchanged = $sourceIntact; workflowCleanupConfirmed = $workflowCleanupConfirmed } }
    finally { $lease.Lock.Dispose(); $backingLock.Dispose() }
}
if (-not $success) { exit 1 }
exit 0
