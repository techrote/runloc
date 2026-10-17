#requires -Version 5.1
# Helpers for the dedicated outer process. No VM or source subprocess starts here
# except through Invoke-PilotSupervisedController's suspended, assigned Job child.
Set-StrictMode -Version Latest

function Read-PilotSupervisorFile {
    param([string]$Path, [int]$MaximumBytes = 262144, [switch]$Json)
    $canonical = Assert-PilotPath -Path $Path -File
    if ($canonical -cne $Path) { throw 'supervisor-path-not-canonical' }
    $stream = [IO.File]::Open($canonical, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    try {
        if ($stream.Length -lt 1 -or $stream.Length -gt $MaximumBytes) { throw 'supervisor-file-size-limit' }
        $bytes = New-Object byte[] ([int]$stream.Length)
        $offset = 0
        while ($offset -lt $bytes.Length) {
            $count = $stream.Read($bytes, $offset, $bytes.Length - $offset)
            if ($count -lt 1) { throw 'supervisor-file-truncated' }
            $offset += $count
        }
        if ($stream.ReadByte() -ne -1) { throw 'supervisor-file-changed' }
        $null = Assert-PilotPath -Path $canonical -File
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $digest = ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant() }
        finally { $sha.Dispose() }
        $value = $null
        if ($Json) {
            $utf8 = New-Object Text.UTF8Encoding($false, $true)
            $text = $utf8.GetString($bytes)
            # ConvertFrom-Json otherwise silently accepts duplicate properties. Tokenize
            # complete strings first, then refuse duplicates (including escaped names).
            $tokens = [regex]::Matches($text, '"(?:\\.|[^"\\])*"|[{}\[\]:]')
            $objects = New-Object 'System.Collections.Generic.Stack[object]'
            for ($index = 0; $index -lt $tokens.Count; $index++) {
                $token = $tokens[$index].Value
                if ($token -ceq '{') { $objects.Push((New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase))) }
                elseif ($token -ceq '[') { $objects.Push($null) }
                elseif ($token -ceq '}' -or $token -ceq ']') { if ($objects.Count) { $null = $objects.Pop() } }
                elseif ($token.StartsWith('"') -and ($index + 1) -lt $tokens.Count -and $tokens[$index + 1].Value -ceq ':' -and $objects.Count -gt 0 -and $null -ne $objects.Peek()) {
                    $key = @(('[' + $token + ']') | ConvertFrom-Json)[0]
                    if (-not $objects.Peek().Add([string]$key)) { throw 'supervisor-json-duplicate-property' }
                }
            }
            # Windows PowerShell preserves strings. PS 7.5+ needs DateKind String
            # to preserve the exact UTC and lease binding bytes before validation.
            if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) { $value = $text | ConvertFrom-Json -DateKind String }
            else { $value = $text | ConvertFrom-Json }
            if ($null -eq $value -or $value -is [array] -or $value -isnot [pscustomobject]) { throw 'supervisor-json-object-required' }
        }
        return [pscustomobject]@{ Path = $canonical; Stream = $stream; Bytes = $bytes; Sha256 = $digest; Value = $value }
    }
    catch { $stream.Dispose(); throw }
}

function Get-PilotSupervisorPins {
    param([string]$Root, [object[]]$Pins, [switch]$RequireExpectedDigest)
    if ($Pins.Count -lt 1 -or $Pins.Count -gt 128) { throw 'supervisor-pin-count-invalid' }
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $result = @()
    foreach ($pin in $Pins) {
        $relative = [string]$pin.path
        if ($relative -cnotmatch '^[A-Za-z0-9_./-]+$' -or $relative.Contains('..') -or
            [IO.Path]::IsPathRooted($relative) -or -not $seen.Add($relative)) { throw 'supervisor-pin-path-invalid' }
        $file = Read-PilotSupervisorFile -Path (Join-Path $Root $relative) -MaximumBytes 4194304
        try {
            $utf8 = New-Object Text.UTF8Encoding($false, $true)
            $text = $utf8.GetString($file.Bytes)
            if ($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) { $text = $text.Substring(1) }
            $text = $text.Replace("`r`n", "`n")
            $sha = [Security.Cryptography.SHA256]::Create()
            try { $lf = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)))).Replace('-', '').ToLowerInvariant() }
            finally { $sha.Dispose() }
            if ($RequireExpectedDigest -and ($pin.sha256Lf -cnotmatch '^[a-f0-9]{64}$' -or $lf -cne $pin.sha256Lf)) { throw 'supervisor-source-pin-mismatch' }
            $result += [pscustomobject]@{ path = $relative; sha256Lf = $lf; executedBytesSha256 = $file.Sha256 }
        }
        finally { $file.Stream.Dispose() }
    }
    return $result
}

function ConvertTo-PilotSupervisorUtc {
    param([object]$Value)
    if ($Value -isnot [string] -or $Value -cnotmatch '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{7}Z$') { throw 'supervisor-utc-not-canonical' }
    $parsed = [DateTime]::MinValue
    if (-not [DateTime]::TryParseExact($Value, 'o', [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::RoundtripKind, [ref]$parsed) -or $parsed.Kind -ne [DateTimeKind]::Utc -or
            $parsed.ToString('o') -cne $Value) { throw 'supervisor-utc-invalid' }
    return $parsed
}

function Assert-PilotSupervisorSource {
    param([object]$Source, [string]$Repository, [string]$Commit, [string]$Tree = '', [object[]]$Pins)
    if ($Source.repository -cne $Repository -or $Source.commit -cne $Commit -or $Source.tree -cnotmatch '^[a-f0-9]{40}$' -or
        ($Tree -and $Source.tree -cne $Tree) -or $Source.clean -isnot [bool] -or -not $Source.clean -or
        @($Source.files).Count -ne $Pins.Count) { throw 'supervisor-source-identity-mismatch' }
    foreach ($pin in $Pins) {
        $actual = @($Source.files | Where-Object { $_.path -ceq $pin.path })
        if ($actual.Count -ne 1 -or $actual[0].sha256Lf -cne $pin.sha256Lf -or
            $actual[0].executedBytesSha256 -cne $pin.executedBytesSha256) { throw 'supervisor-source-file-mismatch' }
    }
}

function Test-PilotSupervisorProcess {
    param([object]$Process)
    foreach ($field in @('childExited', 'forced', 'timedOut', 'outputOverflow', 'outputFailed', 'controllerError')) {
        if ($Process.$field -isnot [bool]) { return $false }
    }
    return ($Process.exitCode -is [int] -and $Process.exitCode -eq 0 -and $Process.childExited -and
        ($Process.activeProcesses -is [int] -or $Process.activeProcesses -is [uint32] -or $Process.activeProcesses -is [long]) -and
        $Process.activeProcesses -eq 0 -and -not $Process.forced -and -not $Process.timedOut -and
        -not $Process.outputOverflow -and -not $Process.outputFailed -and -not $Process.controllerError)
}

function Read-PilotSupervisedReceipt {
    param([object]$Process, [object]$OuterLease, [string]$AttemptsRoot, [string]$StartedUtc,
        [string]$CandidateCommit, [string]$CandidateTree, [object[]]$CandidatePins,
        [string]$ControllerCommit, [object[]]$ControllerPins, [int]$ControllerBudgetSeconds,
        [double]$ElapsedSeconds, [bool]$PreflightOnly)
    if (-not (Test-PilotSupervisorProcess -Process $Process)) { throw 'supervisor-controller-process-incomplete' }
    $markers = @($Process.records | Where-Object { $_.Text.StartsWith('RUNLOC_PILOT_RECEIPT=', [StringComparison]::Ordinal) })
    if ($markers.Count -ne 1 -or $markers[0].Channel -cne 'stdout') { throw 'supervisor-receipt-marker-invalid' }
    $path = $markers[0].Text.Substring('RUNLOC_PILOT_RECEIPT='.Length)
    $canonical = Assert-PilotPath -Path $path -File
    if ($path -cne $canonical -or -not (Test-PilotDescendant -Path $path -Root $AttemptsRoot) -or
        [IO.Path]::GetFileName($path) -cne 'receipt.json') { throw 'supervisor-receipt-path-invalid' }
    $innerRoot = [IO.Path]::GetDirectoryName($path)
    $name = [IO.Path]::GetFileName($innerRoot)
    if ([IO.Path]::GetDirectoryName($innerRoot) -cne $AttemptsRoot -or $name -cnotmatch '^runloc-whpx-([a-f0-9]{32})$') { throw 'supervisor-receipt-parent-invalid' }
    $innerId = $Matches[1]
    # Enumerate only the immediate fresh metadata parent, never an unknown fixture.
    $entries = [IO.Directory]::EnumerateFileSystemEntries($AttemptsRoot).GetEnumerator()
    try {
        if (-not $entries.MoveNext() -or $entries.Current -cne $innerRoot -or $entries.MoveNext()) { throw 'supervisor-attempt-count-invalid' }
    }
    finally { $entries.Dispose() }
    $handles = New-Object 'System.Collections.Generic.List[object]'
    try {
        $lockPath = Assert-PilotPath -Path (Join-Path $innerRoot 'active.lock') -File
        $lock = [IO.File]::Open($lockPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::None)
        $handles.Add($lock)
        if ($lock.Length -ne 0) { throw 'supervisor-inner-lock-invalid' }
        $owner = Read-PilotSupervisorFile -Path (Join-Path $innerRoot 'lease.json') -MaximumBytes 16384 -Json
        $handles.Add($owner.Stream)
        $receiptFile = Read-PilotSupervisorFile -Path $path -MaximumBytes 1048576 -Json
        $handles.Add($receiptFile.Stream)
        $digest = Read-PilotSupervisorFile -Path (Join-Path $innerRoot 'receipt-digest.json') -MaximumBytes 4096 -Json
        $handles.Add($digest.Stream)
        if ($digest.Value.schemaVersion -ne 1 -or $digest.Value.file -cne 'receipt.json' -or
            $digest.Value.sha256 -cnotmatch '^[a-f0-9]{64}$' -or $digest.Value.sha256 -cne $receiptFile.Sha256) { throw 'supervisor-receipt-digest-mismatch' }
        $receipt = $receiptFile.Value
        if ($owner.Value.schemaVersion -ne 1 -or $owner.Value.leaseId -cne $innerId -or $owner.Value.root -cne $innerRoot -or
            $owner.Value.candidateCommit -cne $CandidateCommit -or $owner.Value.controllerCommit -cne $ControllerCommit -or
            $owner.Value.supervisorLeaseId -cne $OuterLease.Id -or $owner.Value.supervisorStartedUtc -cne $StartedUtc -or
            $receipt.schemaVersion -ne 1 -or $receipt.issue -cne 'CI-POC-001' -or $receipt.leaseId -cne $innerId -or
            $receipt.supervisorLeaseId -cne $OuterLease.Id -or $receipt.supervisorStartedUtc -cne $StartedUtc) { throw 'supervisor-receipt-lease-mismatch' }
        $outerStart = ConvertTo-PilotSupervisorUtc -Value $StartedUtc
        $childStart = ConvertTo-PilotSupervisorUtc -Value $Process.createdUtc
        $childEnd = ConvertTo-PilotSupervisorUtc -Value $Process.endedUtc
        $markerUtc = ConvertTo-PilotSupervisorUtc -Value $markers[0].Utc
        $start = ConvertTo-PilotSupervisorUtc -Value $receipt.startedUtc
        $end = ConvertTo-PilotSupervisorUtc -Value $receipt.endedUtc
        $created = ConvertTo-PilotSupervisorUtc -Value $owner.Value.createdUtc
        if ($childStart -lt $outerStart -or $start -lt $childStart -or $created -lt $start -or $created -gt $end -or
            $end -lt $start -or $end -gt $childEnd -or $markerUtc -lt $end -or $markerUtc -gt $childEnd) { throw 'supervisor-receipt-time-binding-invalid' }
        Assert-PilotTelemetryNumber -Value $receipt.elapsedSeconds
        Assert-PilotTelemetryNumber -Value $ElapsedSeconds
        if ($receipt.controllerBudgetSeconds -ne $ControllerBudgetSeconds -or $receipt.hardWallSeconds -ne 5400 -or
            $receipt.targetSeconds -ne 3600 -or $receipt.elapsedSeconds -gt $ElapsedSeconds -or
            [Math]::Abs(($end - $start).TotalSeconds - [double]$receipt.elapsedSeconds) -gt 2 -or
            $ElapsedSeconds -ge 5340 -or $receipt.elapsedSeconds -gt $ControllerBudgetSeconds) { throw 'supervisor-receipt-budget-invalid' }
        Assert-PilotSupervisorSource -Source $receipt.candidate -Repository 'https://github.com/techrote/ezvm' -Commit $CandidateCommit -Tree $CandidateTree -Pins $CandidatePins
        Assert-PilotSupervisorSource -Source $receipt.controller -Repository 'https://github.com/techrote/runloc' -Commit $ControllerCommit -Pins $ControllerPins
        foreach ($field in @('preflightOnly', 'vmQualificationStarted', 'sourceUnchanged', 'timedOut', 'cancelled', 'outputOverflow', 'outputFailed', 'harnessFailure', 'controllerFailure')) {
            if ($receipt.$field -isnot [bool]) { throw 'supervisor-receipt-boolean-invalid' }
        }
        foreach ($field in @('childExited', 'fixtureRemoved', 'forced', 'ownershipVerified')) {
            if ($receipt.cleanup.$field -isnot [bool]) { throw 'supervisor-receipt-boolean-invalid' }
        }
        foreach ($field in @('childExited', 'forced', 'fixtureCreated', 'qualificationStarted')) {
            if ($receipt.preflight.$field -isnot [bool]) { throw 'supervisor-receipt-boolean-invalid' }
        }
        foreach ($number in @($receipt.schemaVersion, $receipt.exitCode, $receipt.cleanup.activeProcesses,
                $receipt.preflight.exitCode, $receipt.preflight.activeProcesses, $receipt.controllerBudgetSeconds, $receipt.hardWallSeconds, $receipt.targetSeconds)) {
            if ($number -isnot [int] -and $number -isnot [long]) { throw 'supervisor-receipt-integer-invalid' }
        }
        if ($receipt.preflightOnly -ne $PreflightOnly -or $receipt.exitCode -ne 0 -or -not $receipt.sourceUnchanged -or
            $receipt.timedOut -or $receipt.cancelled -or $receipt.outputOverflow -or $receipt.outputFailed -or $receipt.harnessFailure -or $receipt.controllerFailure -or
            -not $receipt.cleanup.childExited -or $receipt.cleanup.activeProcesses -ne 0 -or $receipt.cleanup.forced -or
            -not $receipt.cleanup.fixtureRemoved -or -not $receipt.cleanup.ownershipVerified -or
            [IO.Directory]::Exists((Join-Path $innerRoot 'fixture')) -or [IO.File]::Exists((Join-Path $innerRoot 'fixture'))) { throw 'supervisor-inner-outcome-incomplete' }
        if ($PreflightOnly) {
            if ($receipt.outcome -cne 'preflight-pass' -or $receipt.vmQualificationStarted -or $null -ne $receipt.childExitCode -or
                $receipt.preflight.exitCode -ne 0 -or -not $receipt.preflight.childExited -or $receipt.preflight.activeProcesses -ne 0 -or
                $receipt.preflight.forced -or $receipt.preflight.fixtureCreated -or $receipt.preflight.qualificationStarted) { throw 'supervisor-preflight-outcome-invalid' }
        }
        else {
            if ($ElapsedSeconds -gt 3600 -or $receipt.outcome -cne 'pass' -or
                -not (Test-PilotOutcome -Receipt $receipt -LeaseId $innerId -CandidateCommit $CandidateCommit -ControllerCommit $ControllerCommit).Passed) { throw 'supervisor-physical-outcome-invalid' }
            $telemetry = Read-PilotSupervisorFile -Path (Join-Path $innerRoot 'telemetry-events.json') -MaximumBytes 16777216 -Json
            $handles.Add($telemetry.Stream)
            if ($telemetry.Sha256 -cne $receipt.telemetry.publicSha256 -or $telemetry.Value.schemaVersion -ne 1 -or
                @($telemetry.Value.events).Count -ne $receipt.telemetry.recordCount) { throw 'supervisor-telemetry-artifact-invalid' }
        }
        # Keep all read handles and the inner lock through the outer CreateNew receipt.
        # Its recorded byte digest remains the immutable identity of this exact input.
        return [pscustomobject]@{ Receipt = $receipt; Sha256 = $receiptFile.Sha256; OwnerSha256 = $owner.Sha256;
            Label = ('private/attempts/' + $name + '/receipt.json'); LeaseId = $innerId; Handles = $handles }
    }
    catch { foreach ($handle in $handles) { $handle.Dispose() }; throw }
}

function Invoke-PilotSupervisedController {
    param([string]$Executable, [string[]]$Arguments, [string]$WorkingDirectory, [string]$TemporaryDirectory,
        [string]$RawLogPath, [Diagnostics.Stopwatch]$Clock, [object]$Deadline,
        [double]$ExecutionDeadlineSeconds = 5340, [double]$CleanupDeadlineSeconds = 5390)
    $process = $null; $records = New-Object 'System.Collections.Generic.List[object]'
    $result = [ordered]@{ exitCode = $null; childExited = $false; activeProcesses = $null; forced = $false; timedOut = $false;
        outputOverflow = $false; outputFailed = $false; controllerError = $false; createdUtc = ''; endedUtc = ''; records = @() }
    try {
        Assert-PilotDeadline -Clock $Clock -DeadlineSeconds $ExecutionDeadlineSeconds
        $process = New-Object RunlocPoc.OwnedProcess($Executable, $Arguments, $WorkingDirectory, $TemporaryDirectory, $RawLogPath, 2097152)
        $result.createdUtc = $process.CreatedUtc
        $terminate = [Delegate]::CreateDelegate([Action], $process, $process.GetType().GetMethod('Terminate'))
        $Deadline.AttachTermination($terminate)
        while ($true) {
            foreach ($line in $process.Drain()) { $records.Add($line) }
            if ($Deadline.ExecutionExpired -or $Clock.Elapsed.TotalSeconds -ge $ExecutionDeadlineSeconds) { $result.timedOut = $true; break }
            if ($process.OutputOverflow -or $process.OutputFailed -or $process.HasExited) { break }
            Start-Sleep -Milliseconds 100
        }
    }
    catch { $result.controllerError = $true }
    finally {
        if ($null -ne $process) {
            try {
                if (-not $process.HasExited -or $process.ActiveProcesses -ne 0) { $result.forced = $true; $process.Terminate() }
                while ($Clock.Elapsed.TotalSeconds -lt $CleanupDeadlineSeconds -and (-not $process.HasExited -or $process.ActiveProcesses -ne 0)) { Start-Sleep -Milliseconds 50 }
                $result.childExited = $process.HasExited
                $result.activeProcesses = $process.ActiveProcesses
                if ($result.childExited) { $result.exitCode = [int]$process.ExitCode }
                $remaining = [int][Math]::Max(0, [Math]::Min(3000, ($CleanupDeadlineSeconds - $Clock.Elapsed.TotalSeconds) * 1000))
                $result.outputFailed = -not $process.FinishOutput($remaining)
                foreach ($line in $process.Drain()) { $records.Add($line) }
                $result.outputOverflow = $process.OutputOverflow
                $result.outputFailed = $result.outputFailed -or $process.OutputFailed
                if ($result.childExited) { $result.endedUtc = [DateTime]::UtcNow.ToString('o') }
            }
            catch { $result.controllerError = $true }
            finally {
                $Deadline.DetachTermination()
                $process.Dispose()
            }
        }
        if ($Deadline.ExecutionExpired) { $result.timedOut = $true; $result.forced = $true }
        if ($Deadline.StopFailed) { $result.controllerError = $true }
    }
    $result.records = $records.ToArray()
    return [pscustomobject]$result
}
