#requires -Version 5.1
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
Import-PilotNative
$script:passed = 0; $script:skipped = 0
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('runloc synthetic pilot tests ' + [Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($testRoot)
$testFailure = $null

function Assert-True { param([bool]$Condition, [string]$Message = 'assertion failed'); if (-not $Condition) { throw $Message } }
function Assert-Throws {
    param([scriptblock]$Action, [string]$Pattern)
    try { $null = & $Action } catch { if ($_.Exception.Message -match $Pattern) { return }; throw }
    throw ('Expected refusal: ' + $Pattern)
}
function Test-Case {
    param([string]$Name, [scriptblock]$Action)
    try { & $Action; $script:passed++; Write-Host ('PASS ' + $Name) }
    catch { Write-Host ('FAIL ' + $Name); throw }
}
function Remove-PilotTestRoot {
    param([string]$Root)
    # Git creates read-only loose objects on Windows. Validate the complete
    # test-owned inventory before clearing attributes or deleting any file.
    $rootPath = Assert-PilotPath -Path $Root
    if ($rootPath -cne [IO.Path]::GetFullPath($testRoot) -or
        [IO.Path]::GetFileName($rootPath) -cnotmatch '^runloc synthetic pilot tests [a-f0-9]{32}$') { throw 'test-root-ownership-invalid' }
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $stack = New-Object 'System.Collections.Generic.Stack[string]'
    $directories = New-Object 'System.Collections.Generic.List[string]'
    $files = New-Object 'System.Collections.Generic.List[string]'
    $stack.Push($rootPath)
    while ($stack.Count) {
        Assert-PilotDeadline -Clock $clock -DeadlineSeconds 15
        $directory = $stack.Pop(); $null = Assert-PilotPath -Path $directory; $directories.Add($directory)
        foreach ($entry in [IO.Directory]::EnumerateFileSystemEntries($directory)) {
            if (-not (Test-PilotDescendant -Path $entry -Root $rootPath)) { throw 'test-cleanup-path-escape' }
            $null = Assert-PilotPath -Path $entry
            if ([IO.Directory]::Exists($entry)) { $stack.Push($entry) }
            else { $null = Assert-PilotPath -Path $entry -File; $files.Add($entry) }
            if ($files.Count + $directories.Count + $stack.Count -gt 10000) { throw 'test-cleanup-inventory-limit' }
        }
    }
    foreach ($file in $files) {
        Assert-PilotDeadline -Clock $clock -DeadlineSeconds 15
        $null = Assert-PilotPath -Path $file -File
        [IO.File]::SetAttributes($file, [IO.FileAttributes]::Normal)
        [IO.File]::Delete($file)
    }
    for ($index = $directories.Count - 1; $index -ge 0; $index--) {
        Assert-PilotDeadline -Clock $clock -DeadlineSeconds 15
        $null = Assert-PilotPath -Path $directories[$index]
        [IO.Directory]::Delete($directories[$index], $false)
    }
}
function New-TestLease {
    param([switch]$ExternalFixture)
    $parent = Join-Path $testRoot ([Guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($parent)
    $workParent = ''
    if ($ExternalFixture) { $workParent = if ($script:PilotWindows) { $env:USERPROFILE } else { [IO.Path]::GetTempPath() } }
    if ($script:PilotWindows) { return New-PilotLease -EvidenceParent $parent -CandidateCommit ('a' * 40) -ControllerCommit ('b' * 40) -WorkParent $workParent }
    # POSIX tests exercise the pure ownership contract; Windows CI separately exercises real DACLs.
    $id = [Guid]::NewGuid().ToString('N'); $root = Join-Path $parent ('runloc-whpx-' + $id)
    $fixture = Join-Path $root 'fixture'
    if ($ExternalFixture) { $work = Get-PilotWorkPlan -WorkParent $workParent -LeaseId $id; $workParent = $work.Parent; $fixture = $work.Fixture }
    [void][IO.Directory]::CreateDirectory($root)
    $lock = [IO.File]::Open((Join-Path $root 'active.lock'), [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    Write-PilotNewJson -Path (Join-Path $root 'lease.json') -Value @{ schemaVersion = 1; leaseId = $id; root = $root;
        candidateCommit = ('a' * 40); controllerCommit = ('b' * 40); workParent = $workParent; fixture = $fixture }
    return [pscustomobject]@{ Id = $id; Root = $root; Private = (Join-Path $root 'private'); Fixture = $fixture; WorkParent = $workParent;
        Lock = $lock; OwnerDigest = (Get-PilotDigest -Path (Join-Path $root 'lease.json')); CandidateCommit = ('a' * 40); ControllerCommit = ('b' * 40);
        FixtureCreated = $false; FixtureCreationDigest = '' }
}
function New-GoodReceipt {
    $events = @(); $seconds = 1.0; $utc = [DateTime]::UtcNow
    foreach ($line in (@(('EZVM010_STARTED_AT=' + $utc.ToString('o')), 'EZVM010_ACCELERATOR=whpx') + @($script:PilotMarkers | ForEach-Object { $_ + '=PASS' }) + @('EZVM010_COMPLETED_AT=' + $utc.AddSeconds(50).ToString('o')))) {
        $event = ConvertTo-PilotEvidenceEvent -Line $line -Utc $utc.AddSeconds($seconds).ToString('o') -Seconds $seconds
        Assert-True ($null -ne $event) ('Fixture line was not parsed: ' + $line)
        $events += $event; $seconds++
    }
    $guests = @()
    foreach ($root in @('A', 'B')) {
        foreach ($name in @('ezvm010-source', 'ezvm010-stateful', 'ezvm010-imported', 'ezvm012-secondary', 'ezvm012-fresh')) {
            $guests += @{ root = $root; name = $name; state = 'STOPPED'; accelerator = 'whpx'; launchId = [Guid]::NewGuid().ToString('N') }
        }
    }
    return [pscustomobject]@{ schemaVersion = 1; leaseId = ('c' * 32);
        candidate = @{ commit = ('a' * 40); tree = ('1' * 40); executedTreeSha256 = ('1' * 64); clean = $true; repository = 'https://github.com/techrote/ezvm' };
        controller = @{ commit = ('b' * 40); tree = ('2' * 40); executedTreeSha256 = ('2' * 64); clean = $true; repository = 'https://github.com/techrote/runloc' };
        startedUtc = $utc.ToString('o'); endedUtc = $utc.AddSeconds(100).ToString('o');
        preflightOnly = $false; vmQualificationStarted = $true; childExitCode = 0; sourceUnchanged = $true;
        requestedAccelerator = 'whpx'; observedAccelerator = 'whpx'; timedOut = $false; cancelled = $false;
        outputOverflow = $false; outputFailed = $false; harnessFailure = $false; controllerFailure = $false; elapsedSeconds = 100; hardWallSeconds = 5400;
        pathBudget = @{ profile = 'ezvm-pr46-full-release-v1'; fixtureCharacters = 39; relativeReserveCharacters = 215;
            maximumPathCharacters = 259; plannedMaximumCharacters = 254; relativeDirectoryReserveCharacters = 173;
            maximumDirectoryCharacters = 247; plannedMaximumDirectoryCharacters = 212 };
        telemetry = @{ complete = $true; recordCount = 6; publicSha256 = ('3' * 64); publicFile = 'telemetry-events.json' };
        host = @{ standardUser = $true; seSecurityPrivilegePresent = $false };
        preflight = @{ childExited = $true; exitCode = 0; activeProcesses = 0; forced = $false };
        cleanup = @{ childExited = $true; activeProcesses = 0; fixtureRemoved = $true; forced = $false; ownershipVerified = $true; startSeconds = 80; endSeconds = 90 };
        events = $events; identities = @{ sourceImageSha256 = ('d' * 64); expectedImageSha256 = ('d' * 64); baseImageSha256 = ('8' * 64); baseId = 'synthetic-base'; guests = $guests;
            qemuBinaries = @(@{ name = 'qemu-system-x86_64.exe'; sha256 = ('e' * 64) }, @{ name = 'qemu-img.exe'; sha256 = ('f' * 64) }) } }
}
function Test-Receipt { param([object]$Receipt); return Test-PilotOutcome -Receipt $Receipt -LeaseId ('c' * 32) -CandidateCommit ('a' * 40) -ControllerCommit ('b' * 40) }

try {
    Test-Case 'every script parses and Windows native adapter compiles' {
        foreach ($file in Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1') {
            $tokens = $null; $errors = $null
            $null = [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
            Assert-True ($errors.Count -eq 0) ('Parser errors: ' + $file.Name + ' ' + ($errors -join '; '))
        }
    }
    Test-Case 'Framework NUL inventory overload compatibility' { & (Join-Path $PSScriptRoot 'Test-FrameworkSplit.ps1') }
    Test-Case 'full synthetic evidence is accepted only by the pure oracle' {
        Assert-True (Test-Receipt (New-GoodReceipt)).Passed
        Assert-True ($script:PilotMarkers.Count -eq 24)
    }
    Test-Case 'every original completion marker is independently mandatory' {
        foreach ($required in $script:PilotMarkers) {
            $receipt = New-GoodReceipt
            $receipt.events = @($receipt.events | Where-Object { $_.name -cne $required })
            Assert-True (-not (Test-Receipt $receipt).Passed) ('Missing marker accepted: ' + $required)
        }
    }
    Test-Case 'failed exit despite all PASS text is rejected' {
        $receipt = New-GoodReceipt; $receipt.childExitCode = 7
        Assert-True (-not (Test-Receipt $receipt).Passed)
        $receipt.childExitCode = $null; Assert-True (-not (Test-Receipt $receipt).Passed)
    }
    Test-Case 'accelerator request observation and reported evidence must all agree' {
        foreach ($field in @('requestedAccelerator', 'observedAccelerator')) {
            $receipt = New-GoodReceipt; $receipt.$field = 'tcg'; Assert-True (-not (Test-Receipt $receipt).Passed)
        }
        $receipt = New-GoodReceipt
        @($receipt.events | Where-Object { $_.kind -eq 'accelerator' })[0].value = 'tcg'
        Assert-True (-not (Test-Receipt $receipt).Passed)
    }
    Test-Case 'stale lease and candidate or controller replay are rejected' {
        $receipt = New-GoodReceipt; $receipt.leaseId = 'd' * 32
        Assert-True (-not (Test-Receipt $receipt).Passed)
        foreach ($field in @('candidate', 'controller')) {
            $receipt = New-GoodReceipt; $receipt.$field.commit = 'd' * 40
            Assert-True (-not (Test-Receipt $receipt).Passed)
        }
    }
    Test-Case 'timeout cancellation overflow source-change and smoke are not qualification' {
        foreach ($field in @('timedOut', 'cancelled', 'outputOverflow', 'outputFailed', 'harnessFailure', 'controllerFailure', 'preflightOnly')) {
            $receipt = New-GoodReceipt; $receipt.$field = $true; Assert-True (-not (Test-Receipt $receipt).Passed) $field
        }
        foreach ($field in @('sourceUnchanged', 'vmQualificationStarted')) {
            $receipt = New-GoodReceipt; $receipt.$field = $false; Assert-True (-not (Test-Receipt $receipt).Passed) $field
        }
    }
    Test-Case 'sixty-minute target and ninety-minute wall cannot be relaxed' {
        $receipt = New-GoodReceipt; $receipt.elapsedSeconds = 3600; $receipt.endedUtc = ([DateTimeOffset]$receipt.startedUtc).AddSeconds(3600).ToString('o'); Assert-True (Test-Receipt $receipt).Passed
        foreach ($seconds in @(3600.001, 5400, 5400.1, -1)) {
            $receipt = New-GoodReceipt; $receipt.elapsedSeconds = $seconds; Assert-True (-not (Test-Receipt $receipt).Passed)
        }
        $receipt = New-GoodReceipt; $receipt.hardWallSeconds = 5401; Assert-True (-not (Test-Receipt $receipt).Passed)
    }
    Test-Case 'process exit Job emptiness path disposal and ownership are separate gates' {
        foreach ($field in @('childExited', 'fixtureRemoved', 'ownershipVerified')) {
            $receipt = New-GoodReceipt; $receipt.cleanup.$field = $false; Assert-True (-not (Test-Receipt $receipt).Passed) $field
        }
        $receipt = New-GoodReceipt; $receipt.cleanup.activeProcesses = 1; Assert-True (-not (Test-Receipt $receipt).Passed)
        $receipt.cleanup.activeProcesses = 0; $receipt.cleanup.forced = $true; Assert-True (-not (Test-Receipt $receipt).Passed)
    }
    Test-Case 'native UInt32 Job counters retain strict zero-process acceptance' {
        # Controller validation occurs before JSON serialization converts native
        # UInt32 counters to the ordinary integer type used by JSON fixtures.
        Assert-True ([RunlocPoc.OwnedProcess].GetProperty('ActiveProcesses').PropertyType -eq [uint32])
        $receipt = New-GoodReceipt
        $receipt.preflight.activeProcesses = [uint32]0
        $receipt.cleanup.activeProcesses = [uint32]0
        Assert-True (Test-Receipt $receipt).Passed 'A complete native-typed receipt must pass before serialization.'
        foreach ($section in @('preflight', 'cleanup')) {
            foreach ($value in @([uint32]1, [uint32]::MaxValue, '0', $false, 0.0)) {
                $receipt = New-GoodReceipt
                $receipt.$section.activeProcesses = $value
                Assert-True (-not (Test-Receipt $receipt).Passed) ('Invalid native process evidence accepted: ' + $section)
            }
        }
    }
    Test-Case 'duplicate markers missing boundaries and tool-image identity gaps fail' {
        $receipt = New-GoodReceipt; $receipt.events += @($receipt.events | Where-Object { $_.kind -eq 'marker' })[0]
        Assert-True (-not (Test-Receipt $receipt).Passed)
        $receipt = New-GoodReceipt; $receipt.events = @($receipt.events | Where-Object { $_.kind -ne 'boundary' })
        Assert-True (-not (Test-Receipt $receipt).Passed)
        $receipt = New-GoodReceipt; $receipt.identities.sourceImageSha256 = '0' * 64
        Assert-True (-not (Test-Receipt $receipt).Passed)
        $receipt = New-GoodReceipt; $receipt.identities.qemuBinaries = @()
        Assert-True (-not (Test-Receipt $receipt).Passed)
    }
    Test-Case 'coercible strings non-finite numbers and incomplete receipt fields cannot pass' {
        foreach ($field in @('sourceUnchanged', 'preflightOnly', 'timedOut', 'controllerFailure')) {
            $receipt = New-GoodReceipt; $receipt.$field = 'false'; Assert-True (-not (Test-Receipt $receipt).Passed) $field
        }
        foreach ($field in @('childExited', 'fixtureRemoved', 'ownershipVerified', 'forced')) {
            $receipt = New-GoodReceipt; $receipt.cleanup.$field = 'false'; Assert-True (-not (Test-Receipt $receipt).Passed) $field
        }
        foreach ($value in @([double]::NaN, [double]::PositiveInfinity, '100')) {
            $receipt = New-GoodReceipt; $receipt.elapsedSeconds = $value; Assert-True (-not (Test-Receipt $receipt).Passed)
        }
        $receipt = New-GoodReceipt; $receipt.childExitCode = '0'; Assert-True (-not (Test-Receipt $receipt).Passed)
        $receipt = New-GoodReceipt; $receipt.cleanup.activeProcesses = '0'; Assert-True (-not (Test-Receipt $receipt).Passed)
        $receipt = New-GoodReceipt; $receipt.telemetry.recordCount = 6.0; Assert-True (-not (Test-Receipt $receipt).Passed)
        $receipt = New-GoodReceipt; $receipt.preflight = $null; Assert-True (-not (Test-Receipt $receipt).Passed)
        $receipt = New-GoodReceipt; $receipt.host.seSecurityPrivilegePresent = $true; Assert-True (-not (Test-Receipt $receipt).Passed)
        $receipt = New-GoodReceipt; $receipt.pathBudget.fixtureCharacters = '39'; Assert-True (-not (Test-Receipt $receipt).Passed)
        $receipt = New-GoodReceipt; $receipt.pathBudget.relativeReserveCharacters = 200; Assert-True (-not (Test-Receipt $receipt).Passed)
    }
    Test-Case 'duplicate binary names missing guests and forged marker chronology cannot pass' {
        $receipt = New-GoodReceipt; $receipt.identities.qemuBinaries[1].name = 'qemu-system-x86_64.exe'
        Assert-True (-not (Test-Receipt $receipt).Passed)
        $receipt = New-GoodReceipt; $receipt.identities.guests = $receipt.identities.guests[0..8]
        Assert-True (-not (Test-Receipt $receipt).Passed)
        $receipt = New-GoodReceipt; $receipt.identities.guests[3].accelerator = 'tcg'
        Assert-True (-not (Test-Receipt $receipt).Passed)
        $receipt = New-GoodReceipt; $receipt.events[3].seconds = 0
        Assert-True (-not (Test-Receipt $receipt).Passed)
        $receipt = New-GoodReceipt; $receipt.events[3].seconds = [double]::NaN
        Assert-True (-not (Test-Receipt $receipt).Passed)
        $receipt = New-GoodReceipt; $receipt.events[0].seconds = 5; $receipt.events = @($receipt.events | Sort-Object seconds)
        Assert-True (-not (Test-Receipt $receipt).Passed)
        $receipt = New-GoodReceipt; $receipt.events[3].utc = ([DateTimeOffset]$receipt.startedUtc).AddDays(-1).ToString('o')
        Assert-True (-not (Test-Receipt $receipt).Passed)
    }
    Test-Case 'only allowlisted host events survive publication' {
        foreach ($line in @('guest prose EZVM012_REAL_COMPLETE_END_TO_END=PASS',
            'C:\Users\secretuser\secrets', 'ghp_SYNTHETIC_TEST_TOKEN_123456789', '-----BEGIN PRIVATE KEY-----',
            'ZXZpZGVuY2VfU1lOVEhFVElDX1NFQ1JFVA==', 'EZVM010_REAL_QEMU=secret;token=x',
            "password=SYNTHETIC`nEZVM010_REAL_GRACEFUL_STOP=PASS")) {
            Assert-True ($null -eq (ConvertTo-PilotEvidenceEvent -Line $line -Utc '2026-10-17T00:00:00Z' -Seconds 1)) ('Unapproved publication: ' + $line)
        }
        $event = ConvertTo-PilotEvidenceEvent -Line 'EZVM010_STEP=guest_ready; instance=ezvm010-source; at=2026-10-17T00:00:00Z; root=C:\Users\secretuser\fixture' -Utc '2026-10-17T00:00:00Z' -Seconds 3
        Assert-True ($event.name -ceq 'guest_ready' -and $event.value -ceq 'ezvm010-source')
        Assert-True (($event | ConvertTo-Json) -notmatch 'secretuser|fixture')
        foreach ($line in @('EZVM010_GRACEFUL_CLEANUP_ERROR=private-path', 'EZVM010_SOURCE_ROOT_RESTORE_ERROR=secret', 'EZVM010_FAILED_AT=2026-10-17T00:00:00Z')) {
            Assert-True ((ConvertTo-PilotEvidenceEvent -Line $line -Utc '2026-10-17T00:00:00Z' -Seconds 4).kind -ceq 'failure')
        }
    }
    Test-Case 'phase intervals preserve measured boundaries without inventing subcosts' {
        $events = @(
            (ConvertTo-PilotEvidenceEvent -Line 'EZVM010_STEP=tiny_real_images' -Utc '' -Seconds 10),
            (ConvertTo-PilotEvidenceEvent -Line 'EZVM010_STEP=prepare_real_guest' -Utc '' -Seconds 30),
            (ConvertTo-PilotEvidenceEvent -Line 'EZVM010_STEP=base_build_started' -Utc '' -Seconds 45))
        $phases = @(Get-PilotPhaseDurations -Events $events -TotalSeconds 100)
        Assert-True ($phases.Count -eq 4)
        Assert-True ($phases[0].elapsedSeconds -eq 10 -and $phases[1].elapsedSeconds -eq 20 -and
            $phases[2].elapsedSeconds -eq 15 -and $phases[3].elapsedSeconds -eq 55)
    }
    function New-TestTelemetry {
        $utc = '2026-10-17T00:00:00Z'
        return @(
            @{ schemaVersion = 1; sequence = 1; utc = $utc; elapsedSeconds = 0.0; event = 'start'; operationId = 1; parentOperationId = $null; operation = 'full-release'; category = 'qualification'; details = @{} },
            @{ schemaVersion = 1; sequence = 2; utc = $utc; elapsedSeconds = 1.0; event = 'start'; operationId = 2; parentOperationId = 1; operation = 'Import-EzVmManagedInstance'; category = 'image'; details = @{ secret = 'SYNTHETIC-UNAPPROVED-TEXT' } },
            @{ schemaVersion = 1; sequence = 3; utc = $utc; elapsedSeconds = 2.0; event = 'failure'; operationId = 2; parentOperationId = 1; operation = 'Import-EzVmManagedInstance'; category = 'image'; durationSeconds = 1.0; digestTotals = @{ manifest = @{ calls = 2; failedCalls = 1; bytes = 100; elapsedSeconds = 0.1 } } },
            @{ schemaVersion = 1; sequence = 4; utc = $utc; elapsedSeconds = 3.0; event = 'identity'; operationId = 1; parentOperationId = $null; operation = 'verified-identity'; category = 'identity'; details = @{ kind = 'source-image'; sha256 = ('a' * 64); sizeBytes = 64 } },
            @{ schemaVersion = 1; sequence = 5; utc = $utc; elapsedSeconds = 4.0; event = 'end'; operationId = 1; parentOperationId = $null; operation = 'full-release'; category = 'qualification'; durationSeconds = 4.0; digestTotals = @{ manifest = @{ calls = 2; failedCalls = 1; bytes = 100; elapsedSeconds = 0.1 } } }
        )
    }
    function Read-TestTelemetry {
        param([object[]]$Records)
        $directory = Join-Path $testRoot ([Guid]::NewGuid().ToString('N')); [void][IO.Directory]::CreateDirectory($directory)
        $path = Join-Path $directory 'private.jsonl'
        [IO.File]::WriteAllLines($path, @($Records | ForEach-Object { $_ | ConvertTo-Json -Depth 12 -Compress }), (New-Object Text.UTF8Encoding($false)))
        return Read-PilotTelemetry -Path $path -OutputPath (Join-Path $directory 'public.json') -Clock ([Diagnostics.Stopwatch]::StartNew()) -DeadlineSeconds 10
    }
    Test-Case 'nested failure telemetry retains required negative controls and counts hashes once at the root' {
        $summary = Read-TestTelemetry -Records (New-TestTelemetry)
        Assert-True ($summary.complete -and $summary.recordCount -eq 5)
        Assert-True ($summary.digestTotals.manifest.calls -eq 2 -and $summary.digestTotals.manifest.failedCalls -eq 1)
        $nested = @($summary.operations | Where-Object { $_.operation -ceq 'Import-EzVmManagedInstance' })[0]
        Assert-True ($nested.failedCalls -eq 1 -and $nested.inclusiveSeconds -eq 1)
        Assert-True (($summary | ConvertTo-Json -Depth 12) -notmatch 'SYNTHETIC-UNAPPROVED-TEXT')
    }
    Test-Case 'telemetry root failure incomplete nesting stale sequence and unknown operations cannot qualify' {
        $records = New-TestTelemetry; $records[4].event = 'failure'
        Assert-True (-not (Read-TestTelemetry -Records $records).complete)
        $records = New-TestTelemetry; Assert-Throws { Read-TestTelemetry -Records $records[0..3] } 'telemetry-incomplete'
        $records = New-TestTelemetry; $records[2].sequence = 99; Assert-Throws { Read-TestTelemetry -Records $records } 'telemetry-record-invalid'
        $records = New-TestTelemetry; $records[1].parentOperationId = 99; Assert-Throws { Read-TestTelemetry -Records $records } 'telemetry-nesting-invalid'
        $records = New-TestTelemetry; $records[2].operation = 'secret-path'; Assert-Throws { Read-TestTelemetry -Records $records } 'telemetry-record-invalid'
        $records = New-TestTelemetry; $records[4].digestTotals.manifest.failedCalls = 3; Assert-Throws { Read-TestTelemetry -Records $records } 'telemetry-digest-total-invalid'
        $records = New-TestTelemetry; $records[4].elapsedSeconds = 1; Assert-Throws { Read-TestTelemetry -Records $records } 'telemetry-clock-or-operation-invalid'
        $records = New-TestTelemetry; $records[3].details.sha256 = 'secret'; Assert-Throws { Read-TestTelemetry -Records $records } 'telemetry-identity-invalid'
    }
    Test-Case 'failed telemetry parsing releases its file handle before cleanup' {
        $records = New-TestTelemetry; $records[2].sequence = 99
        $path = Join-Path $testRoot 'invalid-telemetry-handle.jsonl'
        [IO.File]::WriteAllLines($path, [string[]]@($records | ForEach-Object { $_ | ConvertTo-Json -Depth 8 -Compress }))
        Assert-Throws { Read-PilotTelemetry -Path $path -OutputPath (Join-Path $testRoot 'invalid-telemetry-public.json') `
            -Clock ([Diagnostics.Stopwatch]::StartNew()) -DeadlineSeconds 10 } 'telemetry-record-invalid'
        $exclusive = [IO.File]::Open($path, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        $exclusive.Dispose()
        [IO.File]::Delete($path)
        Assert-True (-not [IO.File]::Exists($path))
    }

    $source = Join-Path $testRoot 'clean source with spaces'
    [void][IO.Directory]::CreateDirectory($source)
    $null = Invoke-PilotGit -Root $source -Arguments @('init', '--quiet')
    $null = Invoke-PilotGit -Root $source -Arguments @('remote', 'add', 'origin', 'https://github.com/techrote/ezvm.git')
    [IO.File]::WriteAllText((Join-Path $source 'harness.ps1'), "Write-Output 'synthetic'`n")
    [IO.File]::WriteAllText((Join-Path $source '.gitignore'), "runtime/`n")
    [IO.File]::WriteAllText((Join-Path $source '.gitattributes'), "* text eol=lf`nharness.ps1 filter=synthetic`n")
    $null = Invoke-PilotGit -Root $source -Arguments @('add', 'harness.ps1', '.gitignore', '.gitattributes')
    $null = Invoke-PilotGit -Root $source -Arguments @('-c', 'user.name=Runloc synthetic tests', '-c', 'user.email=fixtures@example.invalid', 'commit', '--quiet', '-m', 'Synthetic source identity fixture')
    $head = Invoke-PilotGit -Root $source -Arguments @('rev-parse', 'HEAD')
    $tree = Invoke-PilotGit -Root $source -Arguments @('rev-parse', 'HEAD^{tree}')
    $pins = @([pscustomobject]@{ path = 'harness.ps1'; sha256Lf = (Get-PilotDigest -Path (Join-Path $source 'harness.ps1') -NormalizeText) })
    function Get-TestSource { param([string]$Commit = $head, [string]$Tree = $tree); return Get-PilotSourceIdentity -Root $source -Repository 'https://github.com/techrote/ezvm' -ExpectedCommit $Commit -ExpectedTree $Tree -Pins $pins }
    Test-Case 'real Git exact clean commit tree remote and byte pins are accepted' {
        $identity = Get-TestSource
        Assert-True ($identity.commit -ceq $head -and $identity.tree -ceq $tree -and $identity.clean)
        Assert-True ($identity.trackedFileCount -eq 3) 'The NUL-terminated Git inventories must contain exactly the three tracked files, with no trailing empty entry.'
        Assert-True ($identity.files[0].executedBytesSha256 -cmatch '^[a-f0-9]{64}$')
    }
    Test-Case 'dirty source is rejected and source restoration preserves identity' {
        [IO.File]::AppendAllText((Join-Path $source 'harness.ps1'), '# changed')
        Assert-Throws { Get-TestSource } 'source-public-blob-mismatch'
        $null = Invoke-PilotGit -Root $source -Arguments @('checkout', '--', 'harness.ps1')
        Assert-True (Get-TestSource).clean
    }
    Test-Case 'staged source wrong commit wrong tree and wrong repository are rejected' {
        [IO.File]::AppendAllText((Join-Path $source 'harness.ps1'), '# staged')
        $null = Invoke-PilotGit -Root $source -Arguments @('add', 'harness.ps1')
        Assert-Throws { Get-TestSource } 'source-dirty-or-staged'
        $null = Invoke-PilotGit -Root $source -Arguments @('reset', '--quiet', 'HEAD', '--', 'harness.ps1')
        $null = Invoke-PilotGit -Root $source -Arguments @('checkout', '--', 'harness.ps1')
        Assert-Throws { Get-TestSource -Commit ('f' * 40) } 'source-wrong-commit'
        Assert-Throws { Get-TestSource -Tree ('f' * 40) } 'source-wrong-tree'
        $null = Invoke-PilotGit -Root $source -Arguments @('remote', 'set-url', 'origin', 'https://github.com/other/ezvm')
        Assert-Throws { Get-TestSource } 'source-wrong-repository'
        $null = Invoke-PilotGit -Root $source -Arguments @('remote', 'set-url', 'origin', 'https://github.com/techrote/ezvm.git')
    }
    Test-Case 'ignored mutable runtime untracked files and edited harness pins are rejected' {
        $runtime = Join-Path $source 'runtime'; [void][IO.Directory]::CreateDirectory($runtime)
        [IO.File]::WriteAllText((Join-Path $runtime 'used-disk.txt'), 'synthetic')
        Assert-Throws { Get-TestSource } 'source-dirty-or-staged'
        [IO.File]::Delete((Join-Path $runtime 'used-disk.txt')); [IO.Directory]::Delete($runtime)
        [IO.File]::WriteAllText((Join-Path $source 'untracked.txt'), 'synthetic')
        Assert-Throws { Get-TestSource } 'source-dirty-or-staged'
        [IO.File]::Delete((Join-Path $source 'untracked.txt'))
        $original = $pins[0].sha256Lf; $pins[0].sha256Lf = '0' * 64
        Assert-Throws { Get-TestSource } 'source-pin-mismatch'
        $pins[0].sha256Lf = $original
    }
    Test-Case 'assume-unchanged and skip-worktree flags cannot hide tracked source edits' {
        foreach ($flag in @('assume-unchanged', 'skip-worktree')) {
            $null = Invoke-PilotGit -Root $source -Arguments @('update-index', ('--' + $flag), '--', 'harness.ps1')
            try {
                [IO.File]::AppendAllText((Join-Path $source 'harness.ps1'), '# hidden mutation')
                Assert-Throws { Get-TestSource } 'source-index-flags-unsupported'
            }
            finally {
                $null = Invoke-PilotGit -Root $source -Arguments @('update-index', ('--no-' + $flag), '--', 'harness.ps1')
                $null = Invoke-PilotGit -Root $source -Arguments @('checkout', '--', 'harness.ps1')
            }
        }
    }
    Test-Case 'source verification neither executes nor trusts configured Git clean filters' {
        $null = Invoke-PilotGit -Root $source -Arguments @('config', 'filter.synthetic.clean', 'runloc-deliberately-nonexistent-clean-filter')
        $null = Invoke-PilotGit -Root $source -Arguments @('config', 'filter.synthetic.required', 'true')
        try {
            $file = Join-Path $source 'harness.ps1'; [IO.File]::SetLastWriteTimeUtc($file, [DateTime]::UtcNow)
            Assert-True (Get-TestSource).clean
            [IO.File]::AppendAllText($file, '# filter must never bless this mutation')
            Assert-Throws { Get-TestSource } 'source-public-blob-mismatch'
        }
        finally {
            $null = Invoke-PilotGit -Root $source -Arguments @('config', '--unset', 'filter.synthetic.clean')
            $null = Invoke-PilotGit -Root $source -Arguments @('config', '--unset', 'filter.synthetic.required')
            $null = Invoke-PilotGit -Root $source -Arguments @('checkout', '--', 'harness.ps1')
        }
    }
    Test-Case 'source revalidation refuses mutation after an accepted start snapshot' {
        $initial = Get-TestSource
        [IO.File]::AppendAllText((Join-Path $source 'harness.ps1'), '# changed while running')
        Assert-Throws { Get-PilotSourceIdentity -Root $source -Repository $initial.repository -ExpectedCommit $initial.commit -ExpectedTree $initial.tree -Pins $pins } 'source-public-blob-mismatch'
        $null = Invoke-PilotGit -Root $source -Arguments @('checkout', '--', 'harness.ps1')
    }
    Test-Case 'line-ending mutation preserves the content pin but changes executed bytes' {
        $null = Invoke-PilotGit -Root $source -Arguments @('config', 'core.autocrlf', 'true')
        $file = Join-Path $source 'harness.ps1'; $original = [IO.File]::ReadAllText($file)
        try {
            [IO.File]::WriteAllText($file, $original.Replace("`r`n", "`n"), (New-Object Text.UTF8Encoding($false)))
            $before = Get-TestSource
            $beforeBytes = Get-PilotDigest -Path $file; $beforeLf = Get-PilotDigest -Path $file -NormalizeText
            [IO.File]::WriteAllText($file, $original.Replace("`r`n", "`n").Replace("`n", "`r`n"), (New-Object Text.UTF8Encoding($false)))
            Assert-True ($beforeLf -ceq (Get-PilotDigest -Path $file -NormalizeText))
            Assert-True ($beforeBytes -cne (Get-PilotDigest -Path $file))
        }
        finally {
            [IO.File]::WriteAllText($file, $original, (New-Object Text.UTF8Encoding($false)))
            $null = Invoke-PilotGit -Root $source -Arguments @('config', 'core.autocrlf', 'false')
        }
    }
    Test-Case 'deadline checks stop expired work before source access' {
        $clock = [Diagnostics.Stopwatch]::StartNew()
        Assert-Throws { Get-PilotSourceIdentity -Root $source -Repository 'https://github.com/techrote/ezvm' -ExpectedCommit $head -Clock $clock -DeadlineSeconds 0 } 'deadline-exceeded'
    }
    Test-Case 'CreateNew refuses stale evidence without overwriting bytes' {
        $path = Join-Path $testRoot 'immutable-receipt.json'
        Write-PilotNewJson -Path $path -Value @{ lease = 'original' }
        $digest = Get-PilotDigest -Path $path
        Assert-Throws { Write-PilotNewJson -Path $path -Value @{ lease = 'replayed' } } 'exist|file'
        Assert-True ((Get-PilotDigest -Path $path) -ceq $digest)
    }
    Test-Case 'full-scenario path budget refuses deep parents before creating fixtures' {
        $before = @([IO.Directory]::EnumerateFileSystemEntries($testRoot))
        Assert-Throws { Get-PilotWorkPlan -WorkParent $testRoot -LeaseId ('a' * 32) } 'work-path-budget-exceeded'
        Assert-True (@([IO.Directory]::EnumerateFileSystemEntries($testRoot)).Count -eq $before.Count)
        Assert-Throws { Assert-PilotMetadataBudget -EvidenceParent ('x' * 100) } 'evidence-path-budget-exceeded'
    }
    Test-Case 'exact 44-character fixture boundary fits both measured suffixes and 45 refuses' {
        $budget = (New-GoodReceipt).pathBudget
        $budget.fixtureCharacters = 44; $budget.plannedMaximumCharacters = 259; $budget.plannedMaximumDirectoryCharacters = 217
        Assert-PilotRecordedWorkBudget -Budget $budget -ExpectedFixtureCharacters 44
        Assert-True ($budget.fixtureCharacters + $budget.relativeReserveCharacters -eq 259)
        Assert-True ($budget.fixtureCharacters + $budget.relativeDirectoryReserveCharacters -eq 217 -and $budget.maximumDirectoryCharacters -eq 247)
        $budget.fixtureCharacters = 45; $budget.plannedMaximumCharacters = 260; $budget.plannedMaximumDirectoryCharacters = 218
        Assert-Throws { Assert-PilotRecordedWorkBudget -Budget $budget -ExpectedFixtureCharacters 45 } 'work-path-budget-invalid'
    }
    Test-Case 'compact external fixture mapping preserves every lease bit and refuses overlap' {
        $lease = New-TestLease -ExternalFixture
        try {
            $plan = Get-PilotWorkPlan -WorkParent $lease.WorkParent -LeaseId $lease.Id
            $leaf = [IO.Path]::GetFileName($plan.Fixture)
            Assert-True ($leaf -cmatch '^q[A-Za-z0-9_-]{22}$' -and $plan.Fixture -ceq $lease.Fixture)
            $bytes = [Convert]::FromBase64String($leaf.Substring(1).Replace('-', '+').Replace('_', '/') + '==')
            $decoded = New-Object Guid (,$bytes)
            Assert-True ($decoded.ToString('N') -ceq $lease.Id) 'The compact path must retain all 128 lease bits.'
            Assert-True ($plan.Budget.plannedMaximumCharacters -le 259 -and $plan.Budget.plannedMaximumDirectoryCharacters -le 247)
            Assert-True (-not [IO.Directory]::Exists($lease.Fixture)) 'Lease creation must precede fixture mutation.'
            Assert-PilotFixtureSeparation -Fixture $lease.Fixture -ProtectedRoots @($lease.Root)
            Assert-Throws { Assert-PilotFixtureSeparation -Fixture $lease.Fixture -ProtectedRoots @($lease.Fixture) } 'fixture-and-protected-root-overlap'
            New-PilotFixture -Lease $lease
            [IO.File]::WriteAllText((Join-Path $lease.Fixture 'sentinel.txt'), 'OWNED')
            Assert-Throws { New-PilotFixture -Lease $lease } 'fixture-already-exists'
            $wrong = $lease.Fixture; $lease.Fixture = $lease.Root
            Assert-Throws { Assert-PilotLease -Lease $lease } 'lease-fixture-mismatch'
            $lease.Fixture = $wrong
            Remove-PilotFixture -Lease $lease -Clock ([Diagnostics.Stopwatch]::StartNew()) -DeadlineSeconds 10 -OwnedProcessesExited $true
            Assert-True (-not [IO.Directory]::Exists($lease.Fixture))
        }
        finally { $lease.Lock.Dispose() }
    }
    Test-Case 'refused fixture creation cannot authorize finally to delete existing sentinels' {
        $lease = New-TestLease -ExternalFixture
        $sentinel = Join-Path $lease.Fixture 'unrelated.txt'
        try {
            Remove-PilotFixture -Lease $lease -Clock ([Diagnostics.Stopwatch]::StartNew()) -DeadlineSeconds 10 -OwnedProcessesExited $true
            Assert-True (-not $lease.FixtureCreated -and -not [IO.Directory]::Exists($lease.Fixture))
            [void][IO.Directory]::CreateDirectory($lease.Fixture)
            [IO.File]::WriteAllText($sentinel, 'EXISTING DIRECTORY SENTINEL')
            Assert-Throws { New-PilotFixture -Lease $lease } 'fixture-already-exists'
            Assert-Throws { Remove-PilotFixture -Lease $lease -Clock ([Diagnostics.Stopwatch]::StartNew()) -DeadlineSeconds 10 -OwnedProcessesExited $true } 'cleanup-fixture-not-created'
            Assert-True (-not $lease.FixtureCreated -and [IO.File]::ReadAllText($sentinel) -ceq 'EXISTING DIRECTORY SENTINEL')
            [IO.File]::Delete($sentinel); [IO.Directory]::Delete($lease.Fixture, $false)
            [IO.File]::WriteAllText($lease.Fixture, 'EXISTING FILE SENTINEL')
            Assert-Throws { New-PilotFixture -Lease $lease } 'fixture-already-exists'
            Assert-Throws { Remove-PilotFixture -Lease $lease -Clock ([Diagnostics.Stopwatch]::StartNew()) -DeadlineSeconds 10 -OwnedProcessesExited $true } 'cleanup-fixture-not-created'
            Assert-True (-not $lease.FixtureCreated -and [IO.File]::ReadAllText($lease.Fixture) -ceq 'EXISTING FILE SENTINEL')
        }
        finally {
            # This test, not the refused lease, created these two exact sentinels.
            if ([IO.File]::Exists($sentinel)) { [IO.File]::Delete($sentinel) }
            if ([IO.Directory]::Exists($lease.Fixture)) { [IO.Directory]::Delete($lease.Fixture, $false) }
            if ([IO.File]::Exists($lease.Fixture)) { [IO.File]::Delete($lease.Fixture) }
            $lease.Lock.Dispose()
        }
    }
    Test-Case 'failed durable creation proof quarantines the newly created fixture' {
        $lease = New-TestLease -ExternalFixture
        $proof = Join-Path $lease.Root 'fixture-created.json'
        try {
            [IO.File]::WriteAllText($proof, 'PREEXISTING PROOF SENTINEL')
            Assert-Throws { New-PilotFixture -Lease $lease } 'exist|file'
            Assert-True ($lease.FixtureCreated -and [IO.Directory]::Exists($lease.Fixture))
            Assert-Throws { Remove-PilotFixture -Lease $lease -Clock ([Diagnostics.Stopwatch]::StartNew()) -DeadlineSeconds 10 -OwnedProcessesExited $true } 'cleanup-fixture-creation-unproven'
            Assert-True ([IO.Directory]::Exists($lease.Fixture) -and [IO.File]::ReadAllText($proof) -ceq 'PREEXISTING PROOF SENTINEL')
        }
        finally {
            if ([IO.Directory]::Exists($lease.Fixture)) { [IO.Directory]::Delete($lease.Fixture, $false) }
            $lease.Lock.Dispose()
        }
    }
    Test-Case 'measured longest pinned QEMU member fits the real native path budget' {
        $lease = New-TestLease -ExternalFixture
        try {
            New-PilotFixture -Lease $lease
            $relative = 'ezvm010 qualification ' + ('a' * 32) + '/root A with spaces/runtime/.qemu-stage-' + ('b' * 32) +
                '/share/icons/Adwaita/symbolic/legacy/preferences-desktop-keyboard-shortcuts-symbolic.svg'
            $path = Join-Path $lease.Fixture $relative
            Assert-True (($path.Length - $lease.Fixture.Length) -eq 215)
            [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path))
            [IO.File]::WriteAllText($path, 'SYNTHETIC PAYLOAD BYTES')
            $canonical = Assert-PilotPath -Path $path -File
            Assert-True ([IO.File]::ReadAllText($canonical) -ceq 'SYNTHETIC PAYLOAD BYTES')
            if ($script:PilotWindows) { Assert-True ([RunlocPoc.OwnedProcess]::FileLinkCount($canonical) -eq 1) }
        }
        finally {
            try { Remove-PilotFixture -Lease $lease -Clock ([Diagnostics.Stopwatch]::StartNew()) -DeadlineSeconds 10 -OwnedProcessesExited $true }
            finally { $lease.Lock.Dispose() }
        }
    }
    Test-Case 'owned cleanup deletes only the exact lease fixture and preserves unrelated sentinels' {
        $lease = New-TestLease
        try {
            New-PilotFixture -Lease $lease
            [void][IO.Directory]::CreateDirectory((Join-Path $lease.Fixture 'nested'))
            [IO.File]::WriteAllText((Join-Path $lease.Fixture 'nested/synthetic-disk.txt'), 'owned synthetic bytes')
            [IO.File]::SetAttributes((Join-Path $lease.Fixture 'nested/synthetic-disk.txt'), [IO.FileAttributes]::ReadOnly)
            $sentinel = Join-Path (Split-Path $lease.Root -Parent) 'unrelated sentinel.txt'
            [IO.File]::WriteAllText($sentinel, 'UNRELATED')
            $clock = [Diagnostics.Stopwatch]::StartNew()
            Remove-PilotFixture -Lease $lease -Clock $clock -DeadlineSeconds 10 -OwnedProcessesExited $true
            Assert-True (-not [IO.Directory]::Exists($lease.Fixture))
            Assert-True ([IO.File]::ReadAllText($sentinel) -ceq 'UNRELATED')
        }
        finally { $lease.Lock.Dispose() }
    }
    Test-Case 'wrong ownership unresolved processes changed receipts and expired cleanup refuse deletion' {
        $lease = New-TestLease
        try {
            New-PilotFixture -Lease $lease
            $path = Join-Path $lease.Fixture 'sentinel.txt'; [IO.File]::WriteAllText($path, 'KEEP')
            $clock = [Diagnostics.Stopwatch]::StartNew()
            Assert-Throws { Remove-PilotFixture -Lease $lease -Clock $clock -DeadlineSeconds 10 -OwnedProcessesExited $false } 'cleanup-process-ownership-unresolved'
            Assert-Throws { Remove-PilotFixture -Lease $lease -Clock $clock -DeadlineSeconds 0 -OwnedProcessesExited $true } 'deadline-exceeded'
            $originalFixture = $lease.Fixture; $lease.Fixture = Split-Path $lease.Root -Parent
            Assert-Throws { Remove-PilotFixture -Lease $lease -Clock $clock -DeadlineSeconds 10 -OwnedProcessesExited $true } 'lease-fixture-mismatch'
            $lease.Fixture = $originalFixture
            $creationPath = Join-Path $lease.Root 'fixture-created.json'
            [IO.File]::AppendAllText($creationPath, ' ')
            Assert-Throws { Remove-PilotFixture -Lease $lease -Clock $clock -DeadlineSeconds 10 -OwnedProcessesExited $true } 'cleanup-fixture-creation-proof-changed'
            [IO.File]::AppendAllText((Join-Path $lease.Root 'lease.json'), ' ')
            Assert-Throws { Remove-PilotFixture -Lease $lease -Clock $clock -DeadlineSeconds 10 -OwnedProcessesExited $true } 'lease-receipt-changed'
            Assert-True ([IO.File]::ReadAllText($path) -ceq 'KEEP')
        }
        finally { $lease.Lock.Dispose() }
    }
    Test-Case 'symlink or junction cleanup refuses before deleting any entry' {
        $lease = New-TestLease; $link = ''
        try {
            New-PilotFixture -Lease $lease
            $outside = Join-Path (Split-Path $lease.Root -Parent) 'outside'
            [void][IO.Directory]::CreateDirectory($outside)
            [IO.File]::WriteAllText((Join-Path $outside 'sentinel.txt'), 'OUTSIDE')
            [IO.File]::WriteAllText((Join-Path $lease.Fixture 'owned-sentinel.txt'), 'KEEP')
            $link = Join-Path $lease.Fixture 'redirect'
            $kind = if ($script:PilotWindows) { 'Junction' } else { 'SymbolicLink' }
            $null = New-Item -ItemType $kind -Path $link -Target $outside
            Assert-Throws { Remove-PilotFixture -Lease $lease -Clock ([Diagnostics.Stopwatch]::StartNew()) -DeadlineSeconds 10 -OwnedProcessesExited $true } 'path-reparse-point'
            Assert-True ([IO.File]::ReadAllText((Join-Path $outside 'sentinel.txt')) -ceq 'OUTSIDE')
            Assert-True ([IO.File]::ReadAllText((Join-Path $lease.Fixture 'owned-sentinel.txt')) -ceq 'KEEP')
        }
        finally { if ($link) { [IO.Directory]::Delete($link) }; $lease.Lock.Dispose() }
    }
    Test-Case 'hardlink cleanup refuses before touching external bytes' {
        $lease = New-TestLease
        try {
            New-PilotFixture -Lease $lease
            $outside = Join-Path (Split-Path $lease.Root -Parent) 'outside.txt'; [IO.File]::WriteAllText($outside, 'KEEP')
            $link = Join-Path $lease.Fixture 'hardlink.txt'
            $null = New-Item -ItemType HardLink -Path $link -Target $outside
            Assert-Throws { Remove-PilotFixture -Lease $lease -Clock ([Diagnostics.Stopwatch]::StartNew()) -DeadlineSeconds 10 -OwnedProcessesExited $true } 'file-hardlink'
            Assert-True ([IO.File]::ReadAllText($outside) -ceq 'KEEP')
            [IO.File]::Delete($link)
        }
        finally { $lease.Lock.Dispose() }
    }
    Test-Case 'both relocated roots independently bind every stopped guest accelerator and tool bytes' {
        $lease = New-TestLease -ExternalFixture
        try {
            New-PilotFixture -Lease $lease
            $work = Join-Path $lease.Fixture ('ezvm010 qualification ' + [Guid]::NewGuid().ToString('N'))
            $baseId = 'synthetic-base'; $imageHash = 'a' * 64
            foreach ($rootName in @('root A with spaces', 'moved root B with spaces')) {
                $root = Join-Path $work $rootName
                [void][IO.Directory]::CreateDirectory((Join-Path $root ('runtime/bases/' + $baseId)))
                [IO.File]::WriteAllText((Join-Path $root ('runtime/bases/' + $baseId + '/manifest.json')), (@{ build = @{ accelerator = 'whpx' }; source = @{ imageSha256 = $imageHash }; baseSha256 = ('b' * 64) } | ConvertTo-Json -Depth 6))
                [void][IO.Directory]::CreateDirectory((Join-Path $root 'runtime/qemu'))
                foreach ($toolName in @('qemu-system-x86_64.exe', 'qemu-img.exe')) { [IO.File]::WriteAllText((Join-Path $root ('runtime/qemu/' + $toolName)), ('synthetic bytes: ' + $toolName)) }
                foreach ($name in @('ezvm010-source', 'ezvm010-stateful', 'ezvm010-imported', 'ezvm012-secondary', 'ezvm012-fresh')) {
                    [void][IO.Directory]::CreateDirectory((Join-Path $root ('runtime/instances/' + $name)))
                    [IO.File]::WriteAllText((Join-Path $root ('runtime/instances/' + $name + '/runtime.json')), (@{ instanceName = $name; state = 'STOPPED'; accelerator = 'whpx'; launchId = [Guid]::NewGuid().ToString('N') } | ConvertTo-Json))
                }
            }
            $events = @(
                (ConvertTo-PilotEvidenceEvent -Line ('EZVM010_REAL_BASE=' + $baseId) -Utc '' -Seconds 1),
                (ConvertTo-PilotEvidenceEvent -Line ('EZVM010_REAL_SOURCE_SHA256=' + $imageHash) -Utc '' -Seconds 1),
                (ConvertTo-PilotEvidenceEvent -Line 'EZVM010_REAL_QEMU=11.1.0' -Utc '' -Seconds 1))
            $clock = [Diagnostics.Stopwatch]::StartNew()
            $identity = Get-PilotFixtureIdentity -Lease $lease -Events $events -ExpectedImageSha256 $imageHash -ExpectedQemuVersion '11.1.0' -Clock $clock -DeadlineSeconds 10
            Assert-True ($identity.guests.Count -eq 10 -and $identity.qemuBinaries.Count -eq 2 -and $identity.baseImageSha256 -ceq ('b' * 64))
            $runtimePath = Join-Path $work 'moved root B with spaces/runtime/instances/ezvm010-stateful/runtime.json'
            $original = [IO.File]::ReadAllText($runtimePath)
            $runtime = $original | ConvertFrom-Json; $runtime.accelerator = 'tcg'; [IO.File]::WriteAllText($runtimePath, ($runtime | ConvertTo-Json))
            Assert-Throws { Get-PilotFixtureIdentity -Lease $lease -Events $events -ExpectedImageSha256 $imageHash -ExpectedQemuVersion '11.1.0' -Clock $clock -DeadlineSeconds 10 } 'fixture-guest-not-stopped-or-accelerator-mismatch'
            $runtime.accelerator = 'whpx'; $runtime.state = 'STOPPING'; [IO.File]::WriteAllText($runtimePath, ($runtime | ConvertTo-Json))
            Assert-Throws { Get-PilotFixtureIdentity -Lease $lease -Events $events -ExpectedImageSha256 $imageHash -ExpectedQemuVersion '11.1.0' -Clock $clock -DeadlineSeconds 10 } 'fixture-guest-not-stopped-or-accelerator-mismatch'
            [IO.File]::WriteAllText($runtimePath, $original)
            [IO.File]::AppendAllText((Join-Path $work 'moved root B with spaces/runtime/qemu/qemu-img.exe'), 'modified')
            Assert-Throws { Get-PilotFixtureIdentity -Lease $lease -Events $events -ExpectedImageSha256 $imageHash -ExpectedQemuVersion '11.1.0' -Clock $clock -DeadlineSeconds 10 } 'fixture-relocated-tool-mismatch'
        }
        finally {
            try { Remove-PilotFixture -Lease $lease -Clock ([Diagnostics.Stopwatch]::StartNew()) -DeadlineSeconds 10 -OwnedProcessesExited $true }
            finally { $lease.Lock.Dispose() }
        }
    }

    if ($script:PilotWindows) {
        Test-Case 'private evidence ACL removes broad inherited ACEs without SACL access' {
            $directory = Join-Path $testRoot 'real-private-acl'
            [void][IO.Directory]::CreateDirectory($directory)
            Set-PilotPrivateDirectory -Path $directory
            [IO.File]::WriteAllText((Join-Path $directory 'not-a-key.txt'), 'synthetic')
            $rules = @((Get-Acl -LiteralPath (Join-Path $directory 'not-a-key.txt')).GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]))
            $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            Assert-True ($rules.Count -eq 1 -and $rules[0].IdentityReference.Value -ceq $sid)
        }
        Test-Case 'exact private-key preflight failure precedes fixture and download mutation' {
            $fakeSource = Join-Path $testRoot 'synthetic upstream module'
            $moduleDirectory = Join-Path $fakeSource 'src/EzVm'; [void][IO.Directory]::CreateDirectory($moduleDirectory)
            [IO.File]::WriteAllText((Join-Path $moduleDirectory 'EzVm.psd1'), "@{ RootModule = 'EzVm.psm1'; ModuleVersion = '1.0'; GUID = 'a3b71030-5c9f-48d6-bfe0-0c2cd652bb11' }")
            [IO.File]::WriteAllText((Join-Path $moduleDirectory 'EzVm.psm1'), @'
function Set-EzVmPrivateAcl { param($Path, [switch]$Directory) }
function Protect-EzVmControllerPrivateKey { param($Path); throw 'synthetic-exact-private-key-path-failed' }
'@)
            $lease = New-TestLease
            try {
                $probe = Join-Path $lease.Root 'probe'
                Assert-Throws { Invoke-PilotExactAclPreflight -SourceRoot $fakeSource -ProbeDirectory $probe } 'synthetic-exact-private-key-path-failed'
                Assert-True (-not [IO.Directory]::Exists($lease.Fixture))
                Assert-True (-not [IO.Directory]::Exists((Join-Path $fakeSource 'runtime')))
                Assert-True ([IO.File]::ReadAllText((Join-Path $probe 'not-a-key.txt')) -match 'not a credential')
            }
            finally { $lease.Lock.Dispose() }
        }
        $powershell = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
        Test-Case 'real contained child captures output and actual nonzero exit' {
            $scriptFile = Join-Path $testRoot 'child with spaces.ps1'
            [IO.File]::WriteAllText($scriptFile, "Write-Output 'EZVM012_REAL_COMPLETE_END_TO_END=PASS'`nexit 9`n")
            $clock = [Diagnostics.Stopwatch]::StartNew()
            $result = Invoke-PilotChild -Executable $powershell -Arguments @('-NoLogo', '-NoProfile', '-NonInteractive', '-File', $scriptFile) -WorkingDirectory $testRoot -TemporaryDirectory $testRoot -RawLogPath (Join-Path $testRoot 'child.log') -Clock $clock -ExecutionDeadlineSeconds 15 -CleanupDeadlineSeconds 20
            Assert-True ($result.exitCode -eq 9 -and $result.childExited -and $result.activeProcesses -eq 0 -and -not $result.forced)
            Assert-True (@($result.records | Where-Object { $_.Text -ceq 'EZVM012_REAL_COMPLETE_END_TO_END=PASS' }).Count -eq 1)
        }
        Test-Case 'whole owned descendant tree stops at deadline while unrelated child survives' {
            $parentScript = Join-Path $testRoot 'owned parent.ps1'
            $childScript = Join-Path $testRoot 'owned descendant.ps1'
            [IO.File]::WriteAllText($childScript, 'Start-Sleep -Seconds 60')
            $escapedExe = $powershell.Replace("'", "''"); $escapedChild = $childScript.Replace("'", "''")
            [IO.File]::WriteAllText($parentScript, "`$p = Start-Process -FilePath '$escapedExe' -ArgumentList @('-NoProfile', '-NonInteractive', '-File', '`"$escapedChild`"') -PassThru`nWrite-Output ('DESCENDANT_PID=' + `$p.Id)`nStart-Sleep -Seconds 60")
            $sentinelInfo = New-Object Diagnostics.ProcessStartInfo
            $sentinelInfo.FileName = $powershell; $sentinelInfo.Arguments = '-NoProfile -NonInteractive -Command "Start-Sleep -Seconds 60"'
            $sentinelInfo.UseShellExecute = $false; $sentinelInfo.CreateNoWindow = $true
            $sentinel = [Diagnostics.Process]::Start($sentinelInfo); $null = $sentinel.Handle
            try {
                $clock = [Diagnostics.Stopwatch]::StartNew()
                $result = Invoke-PilotChild -Executable $powershell -Arguments @('-NoLogo', '-NoProfile', '-NonInteractive', '-File', $parentScript) -WorkingDirectory $testRoot -TemporaryDirectory $testRoot -RawLogPath (Join-Path $testRoot 'deadline.log') -Clock $clock -ExecutionDeadlineSeconds 3 -CleanupDeadlineSeconds 10
                Assert-True ($result.timedOut -and $result.forced -and $result.childExited -and $result.activeProcesses -eq 0)
                Assert-True ($clock.Elapsed.TotalSeconds -lt 10)
                Assert-True (@($result.records | Where-Object { $_.Text -cmatch '^DESCENDANT_PID=[0-9]+$' }).Count -eq 1) 'Descendant did not start before timeout.'
                Assert-True (-not $sentinel.HasExited) 'Unrelated owned-by-test sentinel was terminated.'
            }
            finally { if (-not $sentinel.HasExited) { $sentinel.Kill(); $null = $sentinel.WaitForExit(5000) }; $sentinel.Dispose() }
        }
        Test-Case 'controller Job close stops an inherited pipe descendant' {
            $parentScript = Join-Path $testRoot 'owned parent.ps1'
            $job = New-Object RunlocPoc.OwnedProcess($powershell, @('-NoLogo', '-NoProfile', '-NonInteractive', '-File', $parentScript),
                $testRoot, $testRoot, (Join-Path $testRoot 'dispose.log'), 1048576)
            try {
                $deadline = [Diagnostics.Stopwatch]::StartNew(); $childId = $null
                while ($deadline.Elapsed.TotalSeconds -lt 10 -and $null -eq $childId) {
                    foreach ($line in $job.Drain()) { if ($line.Text -cmatch '^DESCENDANT_PID=([0-9]+)$') { $childId = [int]$Matches[1] } }
                    Start-Sleep -Milliseconds 100
                }
                Assert-True ($null -ne $childId)
                $descendant = [Diagnostics.Process]::GetProcessById($childId); $null = $descendant.Handle
                try { $job.Dispose(); Assert-True ($descendant.WaitForExit(5000)) 'Job close left owned descendant alive.' }
                finally { $descendant.Dispose() }
            }
            finally { $job.Dispose() }
        }
        Test-Case 'captured log flood is bounded and cannot produce success' {
            $scriptFile = Join-Path $testRoot 'flood.ps1'
            [IO.File]::WriteAllText($scriptFile, "while (`$true) { Write-Output ('X' * 2000) }")
            $clock = [Diagnostics.Stopwatch]::StartNew(); $log = Join-Path $testRoot 'flood.log'
            $result = Invoke-PilotChild -Executable $powershell -Arguments @('-NoLogo', '-NoProfile', '-NonInteractive', '-File', $scriptFile) -WorkingDirectory $testRoot -TemporaryDirectory $testRoot -RawLogPath $log -Clock $clock -ExecutionDeadlineSeconds 10 -CleanupDeadlineSeconds 15 -MaximumLogBytes 32768
            Assert-True ($result.outputOverflow -and $result.forced -and $result.activeProcesses -eq 0)
            Assert-True ((Get-Item -LiteralPath $log).Length -le 32768)
        }
    }
    else { $script:skipped += 6; Write-Host 'SKIP 6 Windows-only ACL/Job process groups; required Windows CI executes these. No physical WHPX qualification is claimed.' }
    if ([IO.File]::Exists((Join-Path $PSScriptRoot 'Test-Supervisor.ps1'))) {
        Test-Case 'independent outer supervisor contracts' { & (Join-Path $PSScriptRoot 'Test-Supervisor.ps1') }
    }
    Write-Host ('Synthetic pilot contracts: ' + $script:passed + ' PASS; ' + $script:skipped + ' platform groups SKIP; physical WHPX not run.')
}
catch {
    $testFailure = $_
    # Report the primary failure before cleanup; a cleanup exception must never
    # replace the assertion or production error that caused this test to stop.
    Write-Host ('PRIMARY_TEST_FAILURE: ' + $_.Exception.Message)
    Write-Host $_.ScriptStackTrace
    throw
}
finally {
    try { if ([IO.Directory]::Exists($testRoot)) { Remove-PilotTestRoot -Root $testRoot } }
    catch {
        if ($null -eq $testFailure) { throw }
        Write-Warning ('Synthetic test cleanup failed; preserve the primary failure and quarantine this root: ' + $testRoot + '; ' + $_.Exception.Message)
    }
}
