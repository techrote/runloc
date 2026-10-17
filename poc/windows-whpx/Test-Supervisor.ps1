#requires -Version 5.1
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
. (Join-Path $PSScriptRoot 'Pilot.Supervisor.ps1')
Import-PilotNative
if (-not ('RunlocPoc.SupervisorDeadline' -as [type])) { Add-Type -Path (Join-Path $PSScriptRoot 'SupervisorDeadline.cs') }
$script:supervisorPassed = 0; $script:supervisorSkipped = 0
$supervisorTestRoot = Join-Path ([IO.Path]::GetTempPath()) ('runloc supervisor tests ' + [Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($supervisorTestRoot)
function Assert-Supervisor { param([bool]$Condition, [string]$Message = 'supervisor assertion failed'); if (-not $Condition) { throw $Message } }
function Assert-SupervisorThrows {
    param([scriptblock]$Action, [string]$Pattern = 'supervisor-')
    try { $null = & $Action } catch { if ($_.Exception.Message -match $Pattern) { return }; throw }
    throw ('Expected supervisor refusal: ' + $Pattern)
}
function Test-SupervisorCase { param([string]$Name, [scriptblock]$Action); & $Action; $script:supervisorPassed++; Write-Host ('PASS supervisor: ' + $Name) }
function Save-SupervisorFixture {
    param([object]$Fixture, [switch]$KeepDigest)
    $encoding = New-Object Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($Fixture.Path, (($Fixture.Receipt | ConvertTo-Json -Depth 16) + "`n"), $encoding)
    [IO.File]::WriteAllText((Join-Path $Fixture.InnerRoot 'lease.json'), (($Fixture.Owner | ConvertTo-Json -Depth 8) + "`n"), $encoding)
    if (-not $KeepDigest) {
        [IO.File]::WriteAllText((Join-Path $Fixture.InnerRoot 'receipt-digest.json'),
            ((@{ schemaVersion = 1; file = 'receipt.json'; sha256 = (Get-PilotDigest -Path $Fixture.Path) } | ConvertTo-Json) + "`n"), $encoding)
    }
}
function New-SupervisorFixture {
    param([switch]$PreflightOnly)
    $root = Join-Path $supervisorTestRoot ([Guid]::NewGuid().ToString('N'))
    $attempts = Join-Path $root 'private/attempts'
    $id = [Guid]::NewGuid().ToString('N'); $innerRoot = Join-Path $attempts ('runloc-whpx-' + $id)
    [void][IO.Directory]::CreateDirectory($innerRoot)
    [IO.File]::WriteAllBytes((Join-Path $innerRoot 'active.lock'), (New-Object byte[] 0))
    $utc = [DateTime]::UtcNow.AddSeconds(-120); $started = $utc.ToString('o'); $innerStart = $utc.AddSeconds(3)
    $candidatePins = @([pscustomobject]@{ path = 'scripts/harness.ps1'; sha256Lf = ('a' * 64); executedBytesSha256 = ('b' * 64) })
    $controllerPins = @([pscustomobject]@{ path = 'poc/windows-whpx/Invoke-WhpxPilot.ps1'; sha256Lf = ('c' * 64); executedBytesSha256 = ('d' * 64) })
    $owner = [ordered]@{ schemaVersion = 1; leaseId = $id; root = $innerRoot; candidateCommit = ('a' * 40); controllerCommit = ('b' * 40);
        supervisorLeaseId = ('c' * 32); supervisorStartedUtc = $started; createdUtc = $utc.AddSeconds(5).ToString('o') }
    $events = @(); $seconds = 1.0
    foreach ($line in (@(('EZVM010_STARTED_AT=' + $innerStart.ToString('o')), 'EZVM010_ACCELERATOR=whpx') +
        @($script:PilotMarkers | ForEach-Object { $_ + '=PASS' }) + @('EZVM010_COMPLETED_AT=' + $innerStart.AddSeconds(90).ToString('o')))) {
        $events += ConvertTo-PilotEvidenceEvent -Line $line -Utc $innerStart.AddSeconds($seconds).ToString('o') -Seconds $seconds
        $seconds++
    }
    $guests = @()
    foreach ($guestRoot in @('A', 'B')) {
        foreach ($guestName in @('ezvm010-source', 'ezvm010-stateful', 'ezvm010-imported', 'ezvm012-secondary', 'ezvm012-fresh')) {
            $guests += @{ root = $guestRoot; name = $guestName; state = 'STOPPED'; accelerator = 'whpx'; launchId = [Guid]::NewGuid().ToString('N') }
        }
    }
    $receipt = [ordered]@{ schemaVersion = 1; issue = 'CI-POC-001'; leaseId = $id; supervisorLeaseId = ('c' * 32); supervisorStartedUtc = $started;
        startedUtc = $innerStart.ToString('o'); endedUtc = $innerStart.AddSeconds(100).ToString('o'); elapsedSeconds = 100;
        targetSeconds = 3600; hardWallSeconds = 5400; controllerBudgetSeconds = 5338; outcome = 'pass'; exitCode = 0;
        candidate = @{ repository = 'https://github.com/techrote/ezvm'; commit = ('a' * 40); tree = ('d' * 40); executedTreeSha256 = ('1' * 64); clean = $true; files = $candidatePins };
        controller = @{ repository = 'https://github.com/techrote/runloc'; commit = ('b' * 40); tree = ('e' * 40); executedTreeSha256 = ('2' * 64); clean = $true; files = $controllerPins };
        preflightOnly = [bool]$PreflightOnly; vmQualificationStarted = -not [bool]$PreflightOnly; childExitCode = 0; sourceUnchanged = $true;
        requestedAccelerator = 'whpx'; observedAccelerator = 'whpx'; timedOut = $false; cancelled = $false; outputOverflow = $false;
        outputFailed = $false; harnessFailure = $false; controllerFailure = $false;
        telemetry = @{ complete = $true; recordCount = 6; publicSha256 = ('3' * 64); publicFile = 'telemetry-events.json' };
        host = @{ standardUser = $true; seSecurityPrivilegePresent = $false };
        cleanup = @{ childExited = $true; activeProcesses = 0; fixtureRemoved = $true; forced = $false; ownershipVerified = $true; startSeconds = 80; endSeconds = 90 };
        preflight = @{ exitCode = 0; childExited = $true; activeProcesses = 0; forced = $false; fixtureCreated = -not [bool]$PreflightOnly; qualificationStarted = -not [bool]$PreflightOnly };
        events = $events; identities = @{ sourceImageSha256 = ('d' * 64); expectedImageSha256 = ('d' * 64); baseImageSha256 = ('8' * 64); baseId = 'synthetic-base'; guests = $guests;
            qemuBinaries = @(@{ name = 'qemu-system-x86_64.exe'; sha256 = ('e' * 64) }, @{ name = 'qemu-img.exe'; sha256 = ('f' * 64) }) } }
    if ($PreflightOnly) { $receipt.outcome = 'preflight-pass'; $receipt.childExitCode = $null; $receipt.observedAccelerator = '' }
    $telemetryPath = Join-Path $innerRoot 'telemetry-events.json'
    Write-PilotNewJson -Path $telemetryPath -Value @{ schemaVersion = 1; events = @(@{ synthetic = 1 }, @{ synthetic = 2 }, @{ synthetic = 3 }, @{ synthetic = 4 }, @{ synthetic = 5 }, @{ synthetic = 6 }) }
    $receipt.telemetry.publicSha256 = Get-PilotDigest -Path $telemetryPath
    $path = Join-Path $innerRoot 'receipt.json'
    $process = [pscustomobject]@{ exitCode = [int]0; childExited = $true; activeProcesses = 0; forced = $false; timedOut = $false;
        outputOverflow = $false; outputFailed = $false; controllerError = $false; createdUtc = $utc.AddSeconds(2).ToString('o');
        endedUtc = $utc.AddSeconds(105).ToString('o'); records = @([pscustomobject]@{ Channel = 'stdout'; Text = ('RUNLOC_PILOT_RECEIPT=' + $path); Utc = $utc.AddSeconds(104).ToString('o') }) }
    $arguments = @{ Process = $process; OuterLease = [pscustomobject]@{ Id = ('c' * 32) }; AttemptsRoot = $attempts; StartedUtc = $started;
        CandidateCommit = ('a' * 40); CandidateTree = ('d' * 40); CandidatePins = $candidatePins; ControllerCommit = ('b' * 40);
        ControllerPins = $controllerPins; ControllerBudgetSeconds = 5338; ElapsedSeconds = 110; PreflightOnly = [bool]$PreflightOnly }
    $fixture = [pscustomobject]@{ Root = $root; InnerRoot = $innerRoot; Path = $path; Owner = $owner; Receipt = $receipt; Arguments = $arguments }
    Save-SupervisorFixture -Fixture $fixture
    return $fixture
}
function Read-SupervisorFixture {
    param([object]$Fixture)
    $arguments = $Fixture.Arguments
    $validated = Read-PilotSupervisedReceipt @arguments
    try { return [pscustomobject]@{ Sha256 = $validated.Sha256; LeaseId = $validated.LeaseId; Label = $validated.Label; Outcome = $validated.Receipt.outcome } }
    finally { foreach ($handle in $validated.Handles) { $handle.Dispose() } }
}

try {
    Test-SupervisorCase 'dedicated File invocation gate protects an existing owner shell' {
        $script = Join-Path $supervisorTestRoot 'Invoke-WhpxPilot.ps1'
        Assert-Supervisor ([RunlocPoc.SupervisorDeadline]::IsDedicatedFileInvocation(@('powershell.exe', '-NoProfile', '-NonInteractive', '-File', $script, '-CandidateRoot', 'synthetic'), $script, $script))
        foreach ($arguments in @(
            @('powershell.exe'), @('powershell.exe', '-NoProfile', '-NonInteractive', '-Command', ('& ' + $script)),
            @('powershell.exe', '-NoProfile', '-NonInteractive', '-EncodedCommand', 'synthetic', '-File', $script),
            @('powershell.exe', '-NoProfile', '-NonInteractive', '-File', ($script + '.other')),
            @('powershell.exe', '-NonInteractive', '-File', $script))) {
            Assert-Supervisor (-not [RunlocPoc.SupervisorDeadline]::IsDedicatedFileInvocation($arguments, $script, $script))
        }
        Assert-Supervisor (-not [RunlocPoc.SupervisorDeadline]::IsDedicatedFileInvocation(@('powershell.exe', '-NoProfile', '-NonInteractive', '-File', $script), $script, '.'))
    }
    Test-SupervisorCase 'native deadline fires without a PowerShell callback or runspace' {
        $watch = New-Object Diagnostics.Stopwatch
        $deadline = New-Object RunlocPoc.SupervisorDeadline(100, 1000, $false)
        try {
            $deadline.AttachTermination([Delegate]::CreateDelegate([Action], $watch, $watch.GetType().GetMethod('Start')))
            Start-Sleep -Milliseconds 250
            Assert-Supervisor ($deadline.ExecutionExpired -and $watch.IsRunning -and -not $deadline.StopFailed)
            $deadline.DetachTermination(); $deadline.Dispose(); $watch.Stop(); Start-Sleep -Milliseconds 100
            Assert-Supervisor (-not $watch.IsRunning)
        }
        finally { $deadline.Dispose() }
    }
    Test-SupervisorCase 'bounded JSON reads reject duplicate escaped keys oversize and invalid UTF8' {
        $path = Join-Path $supervisorTestRoot 'strict.json'
        foreach ($json in @('{"a":1,"a":2}', '{"a":1,"\u0061":2}', '{"A":1,"a":2}')) {
            [IO.File]::WriteAllText($path, $json)
            Assert-SupervisorThrows { Read-PilotSupervisorFile -Path $path -Json } 'duplicate-property'
        }
        [IO.File]::WriteAllText($path, ('x' * 100))
        Assert-SupervisorThrows { Read-PilotSupervisorFile -Path $path -MaximumBytes 10 } 'file-size-limit'
        [IO.File]::WriteAllBytes($path, [byte[]]@(123, 34, 255, 34, 58, 49, 125))
        Assert-SupervisorThrows { Read-PilotSupervisorFile -Path $path -Json } 'UTF|translate|invalid|Unable'
    }
    Test-SupervisorCase 'fresh full evidence is accepted with an immutable byte digest and safe label' {
        $fixture = New-SupervisorFixture
        $read = Read-SupervisorFixture -Fixture $fixture
        Assert-Supervisor ($read.Outcome -ceq 'pass' -and $read.Sha256 -ceq (Get-PilotDigest -Path $fixture.Path))
        Assert-Supervisor ($read.Label -cmatch '^private/attempts/runloc-whpx-[a-f0-9]{32}/receipt.json$')
    }
    Test-SupervisorCase 'preflight remains distinct from full physical acceptance' {
        $fixture = New-SupervisorFixture -PreflightOnly
        Assert-Supervisor ((Read-SupervisorFixture -Fixture $fixture).Outcome -ceq 'preflight-pass')
        $fixture.Arguments.PreflightOnly = $false
        Assert-SupervisorThrows { Read-SupervisorFixture -Fixture $fixture } 'inner-outcome-incomplete'
        $fixture = New-SupervisorFixture -PreflightOnly; $fixture.Receipt.vmQualificationStarted = $true; Save-SupervisorFixture $fixture
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'preflight-outcome-invalid'
    }
    Test-SupervisorCase 'PASS text cannot overcome nonzero actual exit or unresolved owned processes' {
        foreach ($field in @('exitCode', 'activeProcesses', 'forced', 'timedOut', 'outputOverflow', 'outputFailed', 'controllerError', 'childExited')) {
            $fixture = New-SupervisorFixture
            $fixture.Arguments.Process.$field = if ($field -ceq 'childExited') { $false } elseif ($field -ceq 'exitCode' -or $field -ceq 'activeProcesses') { 9 } else { $true }
            Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'controller-process-incomplete'
        }
    }
    Test-SupervisorCase 'stale copied and replayed supervisor bindings are refused' {
        foreach ($where in @('Owner', 'Receipt')) {
            foreach ($field in @('supervisorLeaseId', 'supervisorStartedUtc', 'leaseId')) {
                $fixture = New-SupervisorFixture
                $fixture.$where.$field = if ($field -ceq 'supervisorStartedUtc') { [DateTime]::UtcNow.AddDays(-1).ToString('o') } else { 'f' * 32 }
                Save-SupervisorFixture $fixture
                Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'lease-mismatch'
            }
        }
    }
    Test-SupervisorCase 'wrong commit tree and actual source bytes fail verification' {
        foreach ($part in @('candidate', 'controller')) {
            foreach ($field in @('commit', 'repository', 'clean')) {
                $fixture = New-SupervisorFixture
                $fixture.Receipt.$part.$field = if ($field -ceq 'clean') { $false } elseif ($field -ceq 'commit') { 'f' * 40 } else { 'https://github.com/other/repository' }
                Save-SupervisorFixture $fixture
                Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'source-identity-mismatch'
            }
        }
        $fixture = New-SupervisorFixture; $fixture.Receipt.candidate.tree = 'f' * 40; Save-SupervisorFixture $fixture
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'source-identity-mismatch'
        $fixture = New-SupervisorFixture
        $fixture.Receipt.controller.files = @([pscustomobject]@{ path = $fixture.Arguments.ControllerPins[0].path; sha256Lf = ('c' * 64); executedBytesSha256 = ('f' * 64) })
        Save-SupervisorFixture $fixture
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'source-file-mismatch'
    }
    Test-SupervisorCase 'strict UTC order and the outer elapsed target bind this actual attempt' {
        foreach ($field in @('startedUtc', 'endedUtc')) {
            $fixture = New-SupervisorFixture; $fixture.Receipt.$field = [DateTime]::UtcNow.AddDays(-1).ToString('o'); Save-SupervisorFixture $fixture
            Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'time-binding-invalid'
        }
        $fixture = New-SupervisorFixture; $fixture.Receipt.startedUtc = '2026-10-17T00:00:00Z'; Save-SupervisorFixture $fixture
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'utc-not-canonical'
        $fixture = New-SupervisorFixture; $fixture.Arguments.ElapsedSeconds = 3600.01
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'physical-outcome-invalid'
        $fixture = New-SupervisorFixture; $fixture.Receipt.elapsedSeconds = 1; Save-SupervisorFixture $fixture
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'budget-invalid'
    }
    Test-SupervisorCase 'receipt marker must be unique actual stdout and within one fresh immediate lease' {
        $fixture = New-SupervisorFixture; $fixture.Arguments.Process.records += $fixture.Arguments.Process.records[0]
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'marker-invalid'
        $fixture = New-SupervisorFixture; $fixture.Arguments.Process.records[0].Channel = 'stderr'
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'marker-invalid'
        $fixture = New-SupervisorFixture; $fixture.Arguments.Process.records = @()
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'marker-invalid'
        $fixture = New-SupervisorFixture; [void][IO.Directory]::CreateDirectory((Join-Path $fixture.Arguments.AttemptsRoot 'another-attempt'))
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'attempt-count-invalid'
        $fixture = New-SupervisorFixture; $outside = New-SupervisorFixture
        $fixture.Arguments.Process.records[0].Text = 'RUNLOC_PILOT_RECEIPT=' + $outside.Path
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'receipt-path-invalid'
    }
    Test-SupervisorCase 'receipt mutation without its original digest is refused' {
        $fixture = New-SupervisorFixture
        [IO.File]::AppendAllText($fixture.Path, ' ')
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'digest-mismatch'
        $fixture = New-SupervisorFixture; [IO.File]::AppendAllText((Join-Path $fixture.InnerRoot 'telemetry-events.json'), ' ')
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'telemetry-artifact-invalid'
    }
    Test-SupervisorCase 'incomplete inner cleanup failure flags telemetry and markers remain failures' {
        $fixture = New-SupervisorFixture; $fixture.Receipt.controllerFailure = $true; Save-SupervisorFixture $fixture
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'inner-outcome-incomplete'
        $fixture = New-SupervisorFixture; $fixture.Receipt.cleanup.forced = $true; Save-SupervisorFixture $fixture
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'inner-outcome-incomplete'
        $fixture = New-SupervisorFixture; $fixture.Receipt.telemetry.complete = $false; Save-SupervisorFixture $fixture
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'physical-outcome-invalid'
        $fixture = New-SupervisorFixture; $fixture.Receipt.events = @(); Save-SupervisorFixture $fixture
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'physical-outcome-invalid'
        $fixture = New-SupervisorFixture; $fixture.Receipt.sourceUnchanged = 'true'; Save-SupervisorFixture $fixture
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'boolean-invalid'
    }
    Test-SupervisorCase 'an unexpected retained fixture is quarantined without deleting its sentinel' {
        $fixture = New-SupervisorFixture; $retained = Join-Path $fixture.InnerRoot 'fixture'
        [void][IO.Directory]::CreateDirectory($retained)
        $sentinel = Join-Path $retained 'unrelated-or-unknown.txt'; [IO.File]::WriteAllText($sentinel, 'KEEP')
        Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'inner-outcome-incomplete'
        Assert-Supervisor ([IO.File]::ReadAllText($sentinel) -ceq 'KEEP')
    }
    Test-SupervisorCase 'receipt hardlinks are refused before reading shared bytes' {
        $fixture = New-SupervisorFixture; $link = Join-Path $fixture.Root 'receipt-copy.json'
        $null = New-Item -ItemType HardLink -Path $link -Target $fixture.Path
        try { Assert-SupervisorThrows { Read-SupervisorFixture $fixture } 'file-hardlink' }
        finally { [IO.File]::Delete($link) }
    }
    if ($script:PilotWindows) {
        $powershell = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
        Test-SupervisorCase 'native watchdog kills a hung controller and nested Job while an unrelated sentinel survives' {
            $nestedScript = Join-Path $supervisorTestRoot 'nested controller.ps1'
            $native = (Join-Path $PSScriptRoot 'OwnedProcess.cs').Replace("'", "''")
            $testPath = $supervisorTestRoot.Replace("'", "''"); $exe = $powershell.Replace("'", "''")
            [IO.File]::WriteAllText($nestedScript, @"
Add-Type -Path '$native'
`$nested = New-Object RunlocPoc.OwnedProcess('$exe', @('-NoProfile', '-NonInteractive', '-Command', 'Start-Sleep -Seconds 60'), '$testPath', '$testPath', '$testPath/nested-private.log', 1048576)
Write-Output 'NESTED_JOB_STARTED'
Start-Sleep -Seconds 60
"@)
            $sentinelInfo = New-Object Diagnostics.ProcessStartInfo
            $sentinelInfo.FileName = $powershell; $sentinelInfo.Arguments = '-NoProfile -NonInteractive -Command "Start-Sleep -Seconds 60"'
            $sentinelInfo.UseShellExecute = $false; $sentinelInfo.CreateNoWindow = $true
            $sentinel = [Diagnostics.Process]::Start($sentinelInfo); $null = $sentinel.Handle
            $job = $null; $deadline = $null
            try {
                $job = New-Object RunlocPoc.OwnedProcess($powershell, @('-NoProfile', '-NonInteractive', '-File', $nestedScript),
                    $supervisorTestRoot, $supervisorTestRoot, (Join-Path $supervisorTestRoot 'outer-native.log'), 1048576)
                $deadline = New-Object RunlocPoc.SupervisorDeadline(7000, 15000, $false)
                $deadline.AttachTermination([Delegate]::CreateDelegate([Action], $job, $job.GetType().GetMethod('Terminate')))
                # Deliberately block this PowerShell thread through the deadline.
                Start-Sleep -Seconds 9
                Assert-Supervisor ($deadline.ExecutionExpired -and -not $deadline.StopFailed -and $job.HasExited -and $job.ActiveProcesses -eq 0)
                Assert-Supervisor ($job.ExitCode -eq 124 -and $job.FinishOutput(1000))
                Assert-Supervisor (@($job.Drain() | Where-Object { $_.Text -ceq 'NESTED_JOB_STARTED' }).Count -eq 1)
                Assert-Supervisor (-not $sentinel.HasExited) 'Unrelated sentinel process was terminated.'
            }
            finally {
                if ($null -ne $deadline) { $deadline.DetachTermination(); $deadline.Dispose() }
                if ($null -ne $job) { $job.Dispose() }
                if (-not $sentinel.HasExited) { $sentinel.Kill(); $null = $sentinel.WaitForExit(5000) }; $sentinel.Dispose()
            }
        }
        Test-SupervisorCase 'dedicated terminal self-exit leaves started evidence and no completion' {
            $scriptFile = Join-Path $supervisorTestRoot 'terminal watchdog child.ps1'
            $native = (Join-Path $PSScriptRoot 'SupervisorDeadline.cs').Replace("'", "''")
            $startedPath = (Join-Path $supervisorTestRoot 'synthetic-started.json').Replace("'", "''")
            [IO.File]::WriteAllText($scriptFile, @"
Add-Type -Path '$native'
`$deadline = New-Object RunlocPoc.SupervisorDeadline(300, 1000, `$true)
[IO.File]::WriteAllText('$startedPath', '{"outcome":"incomplete"}')
Write-Output 'SYNTHETIC_STARTED'
Start-Sleep -Seconds 60
Write-Output 'SYNTHETIC_COMPLETED'
"@)
            $deadline = New-Object RunlocPoc.SupervisorDeadline(15000, 20000, $false)
            try {
                $result = Invoke-PilotSupervisedController -Executable $powershell -Arguments @('-NoProfile', '-NonInteractive', '-File', $scriptFile) `
                    -WorkingDirectory $supervisorTestRoot -TemporaryDirectory $supervisorTestRoot -RawLogPath (Join-Path $supervisorTestRoot 'terminal.log') `
                    -Clock ([Diagnostics.Stopwatch]::StartNew()) -Deadline $deadline -ExecutionDeadlineSeconds 15 -CleanupDeadlineSeconds 18
                Assert-Supervisor ($result.exitCode -eq 124 -and $result.childExited -and $result.activeProcesses -eq 0 -and -not $result.forced)
                Assert-Supervisor (-not (Test-PilotSupervisorProcess -Process $result))
                Assert-Supervisor ([IO.File]::Exists($startedPath))
                Assert-Supervisor (@($result.records | Where-Object { $_.Text -ceq 'SYNTHETIC_COMPLETED' }).Count -eq 0)
            }
            finally { $deadline.Dispose() }
        }
    }
    else { $script:supervisorSkipped = 2; Write-Host 'SKIP 2 Windows-only supervisor Job/watchdog groups; no WHPX qualification is claimed.' }
    Write-Host ('Synthetic supervisor contracts: ' + $script:supervisorPassed + ' PASS; ' + $script:supervisorSkipped + ' platform groups SKIP.')
}
finally {
    # Only test-created synthetic text and handles exist under this random root.
    if ([IO.Directory]::Exists($supervisorTestRoot)) { [IO.Directory]::Delete($supervisorTestRoot, $true) }
}
