#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$CandidateRoot,
    [Parameter(Mandatory = $true)][ValidatePattern('^[a-f0-9]{40}$')][string]$ExpectedControllerCommit,
    [Parameter(Mandatory = $true)][string]$EvidenceParent,
    [Parameter(Mandatory = $true)][string]$WorkParent,
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$')][string]$HostLabel = 'whpx-pilot-host',
    [Parameter(Mandatory = $true)][ValidateRange(0, 5340)][int]$BudgetSeconds,
    [Parameter(Mandatory = $true)][ValidatePattern('^[a-f0-9]{32}$')][string]$SupervisorLeaseId,
    [Parameter(Mandatory = $true)][ValidatePattern('^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z$')][string]$SupervisorStartedUtc,
    [switch]$PreflightOnly,
    [switch]$NoOverallTimeout
)
$clock = [Diagnostics.Stopwatch]::StartNew()
$startedUtc = [DateTime]::UtcNow.ToString('o')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')

# Fixed acceptance bounds, including preflight, evidence, and owned cleanup.
$hardWall = 5400; $target = 3600; $executionDeadline = $BudgetSeconds - 180; $cleanupDeadline = $BudgetSeconds - 45
$sourceDeadline = $BudgetSeconds - 30; $finalSourceDeadline = $BudgetSeconds - 5
if ($NoOverallTimeout) {
    if ($BudgetSeconds -ne 0) { throw 'unbounded-controller-budget-must-be-zero' }
    $hardWall = 0; $target = 0
    $executionDeadline = [double]::PositiveInfinity; $cleanupDeadline = [double]::PositiveInfinity
    $sourceDeadline = [double]::PositiveInfinity; $finalSourceDeadline = [double]::PositiveInfinity
}
elseif ($BudgetSeconds -lt 60) { throw 'bounded-controller-budget-required' }
$controllerRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$lease = $null; $candidate = $null; $controller = $null; $receipt = $null; $child = $null
$exitCode = 2; $reason = 'preflight-blocked'; $sourceUnchanged = $false

try {
    $supervisorStart = [DateTimeOffset]::Parse($SupervisorStartedUtc, [Globalization.CultureInfo]::InvariantCulture)
    if ($supervisorStart -gt [DateTimeOffset]::UtcNow -or (-not $NoOverallTimeout -and ([DateTimeOffset]::UtcNow - $supervisorStart).TotalSeconds -gt 5400)) { throw 'supervisor-start-invalid' }
    if (-not $script:PilotWindows -or -not [Environment]::Is64BitProcess) { throw 'windows-x64-required' }
    Import-PilotNative
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'standard-user-required' }
    if ([RunlocPoc.OwnedProcess]::CurrentTokenHasPrivilege('SeSecurityPrivilege')) { throw 'se-security-privilege-must-be-absent' }
    $controller = Get-PilotSourceIdentity -Root $controllerRoot -Repository 'https://github.com/techrote/runloc' -ExpectedCommit $ExpectedControllerCommit -Clock $clock -DeadlineSeconds $executionDeadline
    foreach ($relative in @('poc/windows-whpx/Invoke-WhpxPilot.ps1', 'poc/windows-whpx/Pilot.Controller.ps1', 'poc/windows-whpx/Invoke-AclPreflight.ps1',
            'poc/windows-whpx/Pilot.Common.ps1', 'poc/windows-whpx/OwnedProcess.cs', 'poc/windows-whpx/Pilot.Supervisor.ps1',
            'poc/windows-whpx/SupervisorDeadline.cs', 'poc/windows-whpx/Pilot.PowerShellEntry.ps1',
            'poc/windows-whpx/Pilot.Bootstrap.ps1', 'poc/windows-whpx/candidate.json')) {
        $path = Assert-PilotPath -Path (Join-Path $controllerRoot $relative) -File
        $controller.files += [ordered]@{ path = $relative; sha256Lf = (Get-PilotDigest -Path $path -NormalizeText);
            executedBytesSha256 = (Get-PilotDigest -Path $path) }
    }
    $configuration = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'candidate.json')) | ConvertFrom-Json
    if ($configuration.schemaVersion -ne 1 -or -not $configuration.executionApproved -or $configuration.repository -cne 'https://github.com/techrote/ezvm' -or
        $configuration.tree -cnotmatch '^[a-f0-9]{40}$' -or $configuration.harness -cne 'scripts/Invoke-EzVm010RealPortability.ps1') { throw 'candidate-not-frozen-for-execution' }
    if (@($configuration.pins | Where-Object { $_.path -ceq $configuration.harness }).Count -ne 1) { throw 'harness-pin-missing' }
    $candidate = Get-PilotSourceIdentity -Root $CandidateRoot -Repository $configuration.repository -ExpectedCommit $configuration.commit -ExpectedTree $configuration.tree -Pins $configuration.pins -Clock $clock -DeadlineSeconds $executionDeadline
    $evidenceParent = Assert-PilotPath -Path $EvidenceParent
    foreach ($root in @($CandidateRoot, $controllerRoot)) {
        if ((Test-PilotDescendant -Path $evidenceParent -Root $root) -or [IO.Path]::GetFullPath($root) -ieq $evidenceParent -or
            (Test-PilotDescendant -Path $root -Root $evidenceParent)) { throw 'source-and-evidence-must-be-separate' }
    }
    if ((Test-PilotDescendant -Path $CandidateRoot -Root $controllerRoot) -or (Test-PilotDescendant -Path $controllerRoot -Root $CandidateRoot)) { throw 'source-checkouts-must-be-separate' }
    $lease = New-PilotLease -EvidenceParent $evidenceParent -CandidateCommit $candidate.commit -ControllerCommit $controller.commit `
        -SupervisorLeaseId $SupervisorLeaseId -SupervisorStartedUtc $SupervisorStartedUtc -WorkParent $WorkParent
    $workPlan = Get-PilotWorkPlan -WorkParent $lease.WorkParent -LeaseId $lease.Id
    Assert-PilotFixtureSeparation -Fixture $lease.Fixture -ProtectedRoots @($CandidateRoot, $controllerRoot, $lease.Root)
    $receipt = [ordered]@{ schemaVersion = 1; issue = 'CI-POC-001'; leaseId = $lease.Id; outcome = 'blocked';
        startedUtc = $startedUtc; endedUtc = ''; elapsedSeconds = 0; targetSeconds = $target; hardWallSeconds = $hardWall; controllerBudgetSeconds = $BudgetSeconds;
        supervisorLeaseId = $SupervisorLeaseId; supervisorStartedUtc = $SupervisorStartedUtc; overallTimeoutDisabled = [bool]$NoOverallTimeout;
        pathBudget = $workPlan.Budget;
        candidate = $candidate; controller = $controller; preflightOnly = [bool]$PreflightOnly;
        vmQualificationStarted = $false; sourceUnchanged = $false; requestedAccelerator = 'whpx'; observedAccelerator = '';
        childExitCode = $null; exitCode = 2; timedOut = $false; cancelled = $false; outputOverflow = $false;
        outputFailed = $false; harnessFailure = $false; controllerFailure = $false; reasonCodes = @(); events = @(); phaseDurations = @();
        host = $null; identities = [ordered]@{ expectedImageSha256 = ''; sourceImageSha256 = ''; qemuBinaries = @() };
        telemetry = [ordered]@{ complete = $false };
        cleanup = [ordered]@{ childExited = $true; activeProcesses = 0; fixtureRemoved = $false;
            forced = $false; ownershipVerified = $false; startSeconds = 0; endSeconds = 0 }; preflight = $null }
    $windowsPowerShell = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    # Windows servicing can legitimately hardlink this system-owned executable; it is never a deletion target.
    $null = Assert-PilotPath -Path $windowsPowerShell -File -AllowHardlink
    $preflightTemp = Join-Path $lease.Private 'preflight-temp'
    [void][IO.Directory]::CreateDirectory($preflightTemp)
    $preflightStart = $clock.Elapsed.TotalSeconds
    $receipt.cleanup.childExited = $false; $receipt.cleanup.activeProcesses = $null
    $preflightArguments = @(Get-PilotPowerShellArguments -TargetScript (Join-Path $PSScriptRoot 'Invoke-AclPreflight.ps1') -NamedParameters @{
        SourceRoot = $CandidateRoot; ProbeDirectory = (Join-Path $lease.Private 'synthetic-acl-probe') })
    $preflight = Invoke-PilotChild -Executable $windowsPowerShell -Arguments $preflightArguments -WorkingDirectory $controllerRoot -TemporaryDirectory $preflightTemp `
        -RawLogPath (Join-Path $lease.Private 'acl-preflight.log') -Clock $clock -ExecutionDeadlineSeconds ([Math]::Min($preflightStart + 120, $executionDeadline)) `
        -CleanupDeadlineSeconds ([Math]::Min($preflightStart + 150, $cleanupDeadline)) -MaximumLogBytes 1048576
    $receipt.preflight = [ordered]@{ exitCode = $preflight.exitCode; elapsedSeconds = $preflight.endSeconds - $preflight.startSeconds;
        childExited = $preflight.childExited; activeProcesses = $preflight.activeProcesses; forced = $preflight.forced;
        ownership = $preflight.ownership; fixtureCreated = $false; qualificationStarted = $false }
    $receipt.cleanup.childExited = $preflight.childExited; $receipt.cleanup.activeProcesses = $preflight.activeProcesses
    $receipt.cleanup.forced = $preflight.forced
    if ($preflight.exitCode -ne 0 -or -not $preflight.childExited -or $preflight.activeProcesses -ne 0 -or $preflight.forced -or
        $preflight.outputOverflow -or $preflight.outputFailed -or @($preflight.records | Where-Object { $_.Text -ceq 'RUNLOC_EXACT_ACL_PREFLIGHT=PASS' }).Count -ne 1) { throw 'exact-acl-preflight-failed' }
    $receipt.cleanup.childExited = $preflight.childExited; $receipt.cleanup.activeProcesses = $preflight.activeProcesses
    $receipt.cleanup.ownershipVerified = $true

    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = @(Get-CimInstance Win32_Processor)
    $hostIdentity = [ordered]@{ label = $HostLabel; os = [string]$os.Caption; version = [string]$os.Version;
        build = [string]$os.BuildNumber; architecture = [string]$os.OSArchitecture; logicalProcessors = [Environment]::ProcessorCount;
        availableMemoryBytes = [long]$os.FreePhysicalMemory * 1KB; cpuModels = @($cpu | ForEach-Object { [string]$_.Name });
        controllerPowerShell = [string]$PSVersionTable.PSVersion; harnessPowerShell = [Diagnostics.FileVersionInfo]::GetVersionInfo($windowsPowerShell).ProductVersion;
        harnessPowerShellSha256 = (Get-PilotDigest -Path $windowsPowerShell); standardUser = $true; seSecurityPrivilegePresent = $false }
    $receipt.host = $hostIdentity
    if ($hostIdentity.availableMemoryBytes -lt 16GB) { throw 'host-memory-prerequisite' }
    $volume = New-Object IO.DriveInfo ([IO.Path]::GetPathRoot($lease.Fixture))
    if ($volume.AvailableFreeSpace -lt 60GB) { throw 'host-free-space-prerequisite' }
    $receipt.host['availableDiskBytes'] = $volume.AvailableFreeSpace
    Assert-PilotDeadline -Clock $clock -DeadlineSeconds $executionDeadline
    if ($PreflightOnly) { $reason = 'preflight-pass'; $exitCode = 0 }
    else {
        Assert-PilotLease -Lease $lease
        # The expensive harness cannot create a fixture or download until the exact ACL probe has succeeded.
        New-PilotFixture -Lease $lease
        $receipt.preflight.fixtureCreated = $true
        $receipt.vmQualificationStarted = $true
        $receipt.preflight.qualificationStarted = $true
        $receipt.cleanup.childExited = $false; $receipt.cleanup.activeProcesses = $null
        $reason = 'full-qualification-failed'
        $harnessArguments = @(Get-PilotPowerShellArguments -TargetScript (Join-Path $CandidateRoot $configuration.harness) -NamedParameters @{
            Root = $CandidateRoot; ReleaseQualification = $true; Accelerator = 'whpx'; TelemetryPath = (Join-Path $lease.Private 'telemetry.jsonl') })
        $child = Invoke-PilotChild -Executable $windowsPowerShell -Arguments $harnessArguments -WorkingDirectory $CandidateRoot -TemporaryDirectory $lease.Fixture `
            -RawLogPath (Join-Path $lease.Private 'qualification.log') -Clock $clock -ExecutionDeadlineSeconds $executionDeadline -CleanupDeadlineSeconds $cleanupDeadline
        $receipt.childExitCode = $child.exitCode; $receipt.timedOut = $child.timedOut; $receipt.outputOverflow = $child.outputOverflow
        $receipt.outputFailed = $child.outputFailed; $receipt.cleanup.childExited = $child.childExited
        $receipt.cleanup.activeProcesses = $child.activeProcesses; $receipt.cleanup.forced = $child.forced
        $events = @()
        foreach ($line in $child.records) {
            $event = ConvertTo-PilotEvidenceEvent -Line $line.Text -Utc $line.Utc -Seconds ($child.startSeconds + $line.Seconds)
            if ($null -ne $event) { $events += $event }
        }
        $receipt.events = $events
        $receipt.harnessFailure = @($events | Where-Object { $_.kind -ceq 'failure' }).Count -gt 0
        $receipt.phaseDurations = Get-PilotPhaseDurations -Events $events -TotalSeconds $child.endSeconds
        $receipt['processOwnership'] = $child.ownership
        $telemetryPath = Join-Path $lease.Private 'telemetry.jsonl'
        if ([IO.File]::Exists($telemetryPath)) {
            $receipt.telemetry = Read-PilotTelemetry -Path $telemetryPath -OutputPath (Join-Path $lease.Root 'telemetry-events.json') -Clock $clock -DeadlineSeconds $cleanupDeadline -NoOverallTimeout:$NoOverallTimeout
        }
        if ($child.exitCode -eq 0 -and $child.childExited -and $child.activeProcesses -eq 0 -and -not $child.forced) {
            $imageManifest = [IO.File]::ReadAllText((Join-Path $CandidateRoot 'manifests/ubuntu-noble-amd64.json')) | ConvertFrom-Json
            $qemuManifest = [IO.File]::ReadAllText((Join-Path $CandidateRoot 'manifests/qemu-windows.json')) | ConvertFrom-Json
            $receipt.identities = Get-PilotFixtureIdentity -Lease $lease -Events $events -ExpectedImageSha256 $imageManifest.sha256 -ExpectedQemuVersion (Get-PilotExpectedQemuVersion -Manifest $qemuManifest) `
                -Clock $clock -DeadlineSeconds $cleanupDeadline
            $receipt.observedAccelerator = 'whpx'
            $identityMatches = @{
                'source-image' = $receipt.identities.sourceImageSha256; 'prepared-base' = $receipt.identities.baseImageSha256;
                'qemu-system' = @($receipt.identities.qemuBinaries | Where-Object { $_.name -ceq 'qemu-system-x86_64.exe' })[0].sha256;
                'qemu-img' = @($receipt.identities.qemuBinaries | Where-Object { $_.name -ceq 'qemu-img.exe' })[0].sha256 }
            foreach ($kind in $identityMatches.Keys) {
                $observations = @($receipt.telemetry.identities | Where-Object { $_.kind -ceq $kind })
                if ($observations.Count -ne 1 -or $observations[0].sha256 -cne $identityMatches[$kind]) { throw 'telemetry-source-tool-identity-mismatch' }
            }
        }
    }
}
catch {
    if ($null -ne $receipt) { $receipt.controllerFailure = $true }
    # Detailed exceptions remain private. Public results use a bounded reason-code vocabulary.
    if ($_.Exception.Message -cmatch '^[a-z][a-z0-9-]{0,90}$') { $reason = $_.Exception.Message }
    else { $reason = 'controller-or-harness-error' }
    if ($null -ne $lease) {
        try { Write-PilotNewJson -Path (Join-Path $lease.Private 'failure.json') -Value @{ error = $_.ToString(); utc = [DateTime]::UtcNow.ToString('o') } } catch { }
    }
    $exitCode = 2
}
finally {
    if ($null -ne $receipt) {
        $receipt.cleanup.startSeconds = $clock.Elapsed.TotalSeconds
        try {
            Assert-PilotLease -Lease $lease
            $receipt.cleanup.ownershipVerified = $true
            Remove-PilotFixture -Lease $lease -Clock $clock -DeadlineSeconds $cleanupDeadline `
                -OwnedProcessesExited ($receipt.cleanup.childExited -and $receipt.cleanup.activeProcesses -eq 0)
            $receipt.cleanup.fixtureRemoved = -not [IO.Directory]::Exists($lease.Fixture)
        }
        catch { $reason = 'owned-cleanup-incomplete'; $receipt.cleanup.fixtureRemoved = $false; $exitCode = 2 }
        $receipt.cleanup.endSeconds = $clock.Elapsed.TotalSeconds
        try {
            Assert-PilotDeadline -Clock $clock -DeadlineSeconds $sourceDeadline
            $afterCandidate = Get-PilotSourceIdentity -Root $CandidateRoot -Repository $configuration.repository -ExpectedCommit $candidate.commit -ExpectedTree $candidate.tree -Pins $configuration.pins -Clock $clock -DeadlineSeconds $finalSourceDeadline
            $afterController = Get-PilotSourceIdentity -Root $controllerRoot -Repository $controller.repository -ExpectedCommit $controller.commit -ExpectedTree $controller.tree -Clock $clock -DeadlineSeconds $finalSourceDeadline
            $receipt.sourceUnchanged = $afterCandidate.tree -ceq $candidate.tree -and $afterController.tree -ceq $controller.tree -and
                $afterCandidate.executedTreeSha256 -ceq $candidate.executedTreeSha256 -and $afterController.executedTreeSha256 -ceq $controller.executedTreeSha256
        }
        catch { $receipt.sourceUnchanged = $false; $reason = 'source-changed-or-unverifiable'; $exitCode = 2 }
        $receipt.elapsedSeconds = $clock.Elapsed.TotalSeconds; $receipt.endedUtc = [DateTime]::UtcNow.ToString('o')
        if ($PreflightOnly -and $reason -ceq 'preflight-pass' -and $receipt.sourceUnchanged -and $receipt.cleanup.fixtureRemoved -and
            ($NoOverallTimeout -or $receipt.elapsedSeconds -lt $hardWall)) { $receipt.outcome = 'preflight-pass'; $receipt.reasonCodes = @('physical-qualification-not-run'); $exitCode = 0 }
        else {
            $outcome = Test-PilotOutcome -Receipt ([pscustomobject]$receipt) -LeaseId $lease.Id -CandidateCommit $candidate.commit -ControllerCommit $controller.commit -NoOverallTimeout:$NoOverallTimeout
            $receipt.reasonCodes = @($outcome.Reasons)
            if ($outcome.Passed) { $receipt.outcome = 'pass'; $exitCode = 0 }
            else { $receipt.outcome = 'failed'; $exitCode = 1; $receipt.reasonCodes += $reason }
        }
        $receipt.exitCode = $exitCode
        try {
            Write-PilotNewJson -Path (Join-Path $lease.Root 'receipt.json') -Value $receipt
            Write-PilotNewJson -Path (Join-Path $lease.Root 'receipt-digest.json') -Value @{ schemaVersion = 1; file = 'receipt.json'; sha256 = (Get-PilotDigest -Path (Join-Path $lease.Root 'receipt.json')) }
            Write-Host ('RUNLOC_PILOT_RECEIPT=' + (Join-Path $lease.Root 'receipt.json'))
            Write-Host ('RUNLOC_PILOT_OUTCOME=' + $receipt.outcome + '; elapsedSeconds=' + $receipt.elapsedSeconds)
        }
        catch { Write-Error 'Pilot could not persist its receipt; acceptance failed.' -ErrorAction Continue; $exitCode = 2 }
    }
    else { Write-Error ('Pilot blocked before a qualification lease was created: ' + $reason) -ErrorAction Continue }
    if ($null -ne $lease -and $null -ne $lease.Lock) { $lease.Lock.Dispose() }
}
exit $exitCode
