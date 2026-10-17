#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$CandidateRoot,
    [Parameter(Mandatory = $true)][ValidatePattern('^[a-f0-9]{40}$')][string]$ExpectedControllerCommit,
    [Parameter(Mandatory = $true)][string]$EvidenceParent,
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$')][string]$HostLabel = 'whpx-pilot-host',
    [switch]$PreflightOnly
)
$clock = [Diagnostics.Stopwatch]::StartNew()
$startedUtc = [DateTime]::UtcNow.ToString('o')
$ErrorActionPreference = 'Stop'

# Bootstrap occurs before any source check, lease, child, or qualification fixture.
# Its elapsed time is charged against the same absolute deadlines. A dedicated
# -File process is mandatory: the terminal timer must never end an owner's shell.
if (-not ('RunlocPoc.SupervisorDeadline' -as [type])) {
    Add-Type -Path (Join-Path $PSScriptRoot 'SupervisorDeadline.cs') -ErrorAction Stop
}
if (-not [RunlocPoc.SupervisorDeadline]::IsDedicatedFileInvocation([Environment]::GetCommandLineArgs(), $PSCommandPath, $MyInvocation.InvocationName)) {
    throw 'Launch a dedicated powershell.exe -NoProfile -NonInteractive -File Invoke-WhpxPilot.ps1 process.'
}
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT -or -not [Environment]::Is64BitProcess) {
    Write-Error 'The supervised pilot requires a native Windows x64 process.' -ErrorAction Continue
    exit 2
}
$remainingExecution = [int][Math]::Floor((5340 - $clock.Elapsed.TotalSeconds) * 1000)
$remainingTerminal = [int][Math]::Floor((5400 - $clock.Elapsed.TotalSeconds) * 1000)
if ($remainingExecution -lt 60000 -or $remainingTerminal -le $remainingExecution) {
    Write-Error 'The supervisor bootstrap exhausted its launch budget; qualification did not start.' -ErrorAction Continue
    exit 124
}
$deadline = New-Object RunlocPoc.SupervisorDeadline($remainingExecution, $remainingTerminal, $true)
$lease = $null; $validated = $null; $configurationFile = $null; $receipt = $null; $process = $null
$exitCode = 2; $reason = 'supervisor-bootstrap-or-source-failed'; $controllerBudget = 0

try {
    . (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
    . (Join-Path $PSScriptRoot 'Pilot.Supervisor.ps1')
    Import-PilotNative
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -or
        [RunlocPoc.OwnedProcess]::CurrentTokenHasPrivilege('SeSecurityPrivilege')) { throw 'standard-token-required' }
    $controllerRoot = Assert-PilotPath -Path ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')))
    $candidatePath = Assert-PilotPath -Path $CandidateRoot
    $parent = Assert-PilotPath -Path $EvidenceParent
    foreach ($root in @($candidatePath, $controllerRoot)) {
        if ($root -ieq $parent -or (Test-PilotDescendant -Path $parent -Root $root) -or
            (Test-PilotDescendant -Path $root -Root $parent)) { throw 'source-and-evidence-must-be-separate' }
    }
    if ($candidatePath -ieq $controllerRoot -or (Test-PilotDescendant -Path $candidatePath -Root $controllerRoot) -or
        (Test-PilotDescendant -Path $controllerRoot -Root $candidatePath)) { throw 'source-checkouts-must-be-separate' }
    $configurationFile = Read-PilotSupervisorFile -Path (Join-Path $PSScriptRoot 'candidate.json') -MaximumBytes 65536 -Json
    $configuration = $configurationFile.Value
    if ($configuration.schemaVersion -ne 1 -or $configuration.executionApproved -isnot [bool] -or -not $configuration.executionApproved -or
        $configuration.repository -cne 'https://github.com/techrote/ezvm' -or $configuration.commit -cnotmatch '^[a-f0-9]{40}$' -or
        $configuration.tree -cnotmatch '^[a-f0-9]{40}$' -or $configuration.harness -cne 'scripts/Invoke-EzVm010RealPortability.ps1' -or
        @($configuration.pins | Where-Object { $_.path -ceq $configuration.harness }).Count -ne 1) { throw 'candidate-not-frozen-for-execution' }
    $candidatePins = @(Get-PilotSupervisorPins -Root $candidatePath -Pins $configuration.pins -RequireExpectedDigest)
    $controllerNames = @('poc/windows-whpx/Invoke-WhpxPilot.ps1', 'poc/windows-whpx/Pilot.Controller.ps1',
        'poc/windows-whpx/Invoke-AclPreflight.ps1', 'poc/windows-whpx/Pilot.Common.ps1', 'poc/windows-whpx/OwnedProcess.cs',
        'poc/windows-whpx/Pilot.Supervisor.ps1', 'poc/windows-whpx/SupervisorDeadline.cs', 'poc/windows-whpx/candidate.json')
    $controllerPins = @(Get-PilotSupervisorPins -Root $controllerRoot -Pins @($controllerNames | ForEach-Object { [pscustomobject]@{ path = $_ } }))
    Assert-PilotDeadline -Clock $clock -DeadlineSeconds 5100
    $lease = New-PilotLease -EvidenceParent $parent -CandidateCommit $configuration.commit -ControllerCommit $ExpectedControllerCommit
    $attempts = Join-Path $lease.Private 'attempts'
    $temporary = Join-Path $lease.Private 'controller-temp'
    [void][IO.Directory]::CreateDirectory($attempts)
    [void][IO.Directory]::CreateDirectory($temporary)
    # This immutable record is deliberately distinct from a completed receipt. If
    # terminal self-exit interrupts later I/O, its absence of completion is failure.
    $started = [ordered]@{ schemaVersion = 1; issue = 'CI-POC-001'; kind = 'supervisor-started'; supervisorLeaseId = $lease.Id;
        startedUtc = $startedUtc; candidateCommit = $configuration.commit; candidateTree = $configuration.tree;
        controllerCommit = $ExpectedControllerCommit; preflightOnly = [bool]$PreflightOnly; hostLabel = $HostLabel;
        targetSeconds = 3600; executionDeadlineSeconds = 5340; cleanupDeadlineSeconds = 5390; hardWallSeconds = 5400;
        completedReceipt = 'supervisor-receipt.json'; incompleteMeansFailure = $true }
    Write-PilotNewJson -Path (Join-Path $lease.Root 'supervisor-started.json') -Value $started
    Write-Host ('RUNLOC_WHPX_SUPERVISOR_STARTED=' + (Join-Path $lease.Root 'supervisor-started.json'))
    $receipt = [ordered]@{ schemaVersion = 1; issue = 'CI-POC-001'; kind = 'supervisor'; supervisorLeaseId = $lease.Id;
        outcome = 'failed'; exitCode = 2; startedUtc = $startedUtc; endedUtc = ''; elapsedSeconds = 0;
        targetSeconds = 3600; executionDeadlineSeconds = 5340; cleanupDeadlineSeconds = 5390; hardWallSeconds = 5400;
        controllerBudgetSeconds = 0; preflightOnly = [bool]$PreflightOnly; physicalQualificationPassed = $false; hostLabel = $HostLabel;
        elapsedSecondsScope = 'through-outcome-evaluation-before-receipt-write';
        acceptanceRequires = @('matching-receipt-digest', 'terminal-outcome-marker-with-post-io-elapsed', 'actual-supervisor-exit-zero');
        candidate = [ordered]@{ repository = $configuration.repository; commit = $configuration.commit; tree = $configuration.tree; files = $candidatePins };
        controller = [ordered]@{ repository = 'https://github.com/techrote/runloc'; commit = $ExpectedControllerCommit; tree = ''; files = $controllerPins };
        reasonCodes = @(); controllerProcess = $null; inner = $null;
        quarantine = [ordered]@{ required = $true; label = 'private/attempts'; mayContainQualificationFixture = $false } }
    $windowsPowerShell = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $null = Assert-PilotPath -Path $windowsPowerShell -File -AllowHardlink
    $controllerBudget = [int][Math]::Floor(5340 - $clock.Elapsed.TotalSeconds)
    if ($controllerBudget -lt 240 -or $controllerBudget -gt 5340 -or $deadline.ExecutionExpired) { throw 'controller-launch-budget-exhausted' }
    $receipt.controllerBudgetSeconds = $controllerBudget
    $arguments = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'Pilot.Controller.ps1'),
        '-CandidateRoot', $candidatePath, '-ExpectedControllerCommit', $ExpectedControllerCommit, '-EvidenceParent', $attempts,
        '-HostLabel', $HostLabel, '-BudgetSeconds', [string]$controllerBudget, '-SupervisorLeaseId', $lease.Id, '-SupervisorStartedUtc', $startedUtc)
    if ($PreflightOnly) { $arguments += '-PreflightOnly' }
    $reason = 'supervisor-controller-incomplete'
    $receipt.quarantine.mayContainQualificationFixture = -not [bool]$PreflightOnly
    $process = Invoke-PilotSupervisedController -Executable $windowsPowerShell -Arguments $arguments -WorkingDirectory $controllerRoot `
        -TemporaryDirectory $temporary -RawLogPath (Join-Path $lease.Private 'controller.log') -Clock $clock -Deadline $deadline
    $receipt.controllerProcess = [ordered]@{ method = 'CreateProcess-suspended-then-Job-assignment'; killOnClose = $true; breakawayAllowed = $false;
        createdUtc = $process.createdUtc; endedUtc = $process.endedUtc; exitCode = $process.exitCode; childExited = $process.childExited;
        activeProcesses = $process.activeProcesses; forced = $process.forced; timedOut = $process.timedOut;
        outputOverflow = $process.outputOverflow; outputFailed = $process.outputFailed; controllerError = $process.controllerError }
    if (-not (Test-PilotSupervisorProcess -Process $process) -or $deadline.ExecutionExpired -or $deadline.StopFailed) { throw 'controller-process-incomplete' }
    $reason = 'supervisor-inner-receipt-invalid'
    Assert-PilotDeadline -Clock $clock -DeadlineSeconds 5390
    Assert-PilotLease -Lease $lease
    $validated = Read-PilotSupervisedReceipt -Process $process -OuterLease $lease -AttemptsRoot $attempts -StartedUtc $startedUtc `
        -CandidateCommit $configuration.commit -CandidateTree $configuration.tree -CandidatePins $candidatePins -ControllerCommit $ExpectedControllerCommit `
        -ControllerPins $controllerPins -ControllerBudgetSeconds $controllerBudget -ElapsedSeconds $clock.Elapsed.TotalSeconds -PreflightOnly ([bool]$PreflightOnly)
    $receipt.inner = [ordered]@{ label = $validated.Label; leaseId = $validated.LeaseId; receiptSha256 = $validated.Sha256;
        leaseSha256 = $validated.OwnerSha256; outcome = $validated.Receipt.outcome; validated = $true }
    $receipt.controller.tree = $validated.Receipt.controller.tree
    $receipt.quarantine.required = $false; $receipt.quarantine.mayContainQualificationFixture = $false
    $receipt.outcome = if ($PreflightOnly) { 'preflight-pass' } else { 'pass' }
    $receipt.physicalQualificationPassed = -not [bool]$PreflightOnly
    $reason = if ($PreflightOnly) { 'physical-qualification-not-run' } else { 'complete-physical-qualification' }
    $exitCode = 0
}
catch {
    # All raw child output remains private. Public codes are assigned by our own
    # stage transitions; exception text and arbitrary child fields are not copied.
    if ($deadline.ExecutionExpired -or $clock.Elapsed.TotalSeconds -ge 5340) { $reason = 'supervisor-deadline-exceeded'; $exitCode = 124 }
    else { $exitCode = 2 }
}
finally {
    try {
        if ($null -ne $receipt) {
            $receipt.elapsedSeconds = $clock.Elapsed.TotalSeconds
            if ($deadline.ExecutionExpired -or $deadline.StopFailed -or $receipt.elapsedSeconds -ge 5340 -or
                (-not $PreflightOnly -and $receipt.elapsedSeconds -gt 3600)) {
                $receipt.outcome = 'failed'; $receipt.physicalQualificationPassed = $false; $exitCode = 124; $reason = 'supervisor-target-or-deadline-exceeded'
            }
            if ($exitCode -ne 0) { $receipt.outcome = 'failed'; $receipt.physicalQualificationPassed = $false }
            $receipt.exitCode = $exitCode; $receipt.reasonCodes = @($reason); $receipt.endedUtc = [DateTime]::UtcNow.ToString('o')
            Assert-PilotDeadline -Clock $clock -DeadlineSeconds 5399
            Write-PilotNewJson -Path (Join-Path $lease.Root 'supervisor-receipt.json') -Value $receipt
            $written = Read-PilotSupervisorFile -Path (Join-Path $lease.Root 'supervisor-receipt.json') -MaximumBytes 262144
            try {
                Write-PilotNewJson -Path (Join-Path $lease.Root 'supervisor-receipt-digest.json') -Value @{ schemaVersion = 1; file = 'supervisor-receipt.json'; sha256 = $written.Sha256 }
            }
            finally { $written.Stream.Dispose() }
            # Close every evidence handle before reporting the final elapsed time.
            # The native terminal deadline stays armed during these operations.
            if ($null -ne $validated) { foreach ($handle in $validated.Handles) { $handle.Dispose() }; $validated = $null }
            if ($null -ne $configurationFile) { $configurationFile.Stream.Dispose(); $configurationFile = $null }
            if ($null -ne $lease.Lock) { $lease.Lock.Dispose(); $lease.Lock = $null }
            $finalElapsed = $clock.Elapsed.TotalSeconds
            $finalOutcome = [string]$receipt.outcome
            if ($deadline.ExecutionExpired -or $deadline.StopFailed -or $finalElapsed -ge 5340 -or
                (-not $PreflightOnly -and $finalElapsed -gt 3600)) { $exitCode = 124; $finalOutcome = 'failed' }
            Write-Host ('RUNLOC_WHPX_SUPERVISOR_RECEIPT=' + (Join-Path $lease.Root 'supervisor-receipt.json'))
            Write-Host ('RUNLOC_WHPX_SUPERVISOR_OUTCOME=' + $finalOutcome + '; elapsedSeconds=' + $finalElapsed.ToString('R', [Globalization.CultureInfo]::InvariantCulture))
            # A blocked output consumer must not turn a late marker into success.
            if ($clock.Elapsed.TotalSeconds -ge 5340 -or (-not $PreflightOnly -and $clock.Elapsed.TotalSeconds -gt 3600)) { $exitCode = 124 }
        }
        else { Write-Error ('The supervised pilot stopped before launch: ' + $reason) -ErrorAction Continue }
    }
    catch { Write-Error 'The supervisor could not complete its immutable receipt; acceptance failed.' -ErrorAction Continue; $exitCode = 2 }
    finally {
        if ($null -ne $validated) { foreach ($handle in $validated.Handles) { $handle.Dispose() } }
        if ($null -ne $configurationFile) { $configurationFile.Stream.Dispose() }
        if ($null -ne $lease -and $null -ne $lease.Lock) { $lease.Lock.Dispose() }
        $deadline.Dispose()
    }
}
exit $exitCode
