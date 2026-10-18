#requires -Version 5.1
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Console.Monitor.ps1')
$count=0
function Assert-Monitor {param([bool]$Value) if(-not $Value){throw 'monitor-assertion-failed'}}
function Test-Monitor {param([string]$Name,[scriptblock]$Body) & $Body;$script:count++;Write-Host ('PASS monitor: '+$Name)}
Test-Monitor 'retained old telemetry with no process is never live progress' {
    Assert-Monitor ((Get-ConsoleActivityState -ControllerKnown $false -ControllerAlive $false -ListenerAlive $false -HasFinal $false -TelemetryAgeSeconds 10000) -ceq 'NO_ACTIVE_RUN_RETAINED_EVIDENCE')
    Assert-Monitor ((Get-ConsoleActivityState -ControllerKnown $true -ControllerAlive $false -ListenerAlive $false -HasFinal $false -TelemetryAgeSeconds 0) -ceq 'INTERRUPTED_NO_FINAL_RECEIPT')
}
Test-Monitor 'quiet live phases and final receipts remain distinct from qualification' {
    Assert-Monitor ((Get-ConsoleActivityState -ControllerKnown $true -ControllerAlive $true -ListenerAlive $true -HasFinal $false -TelemetryAgeSeconds 121) -ceq 'RUNNING_TELEMETRY_QUIET')
    Assert-Monitor ((Get-ConsoleActivityState -ControllerKnown $true -ControllerAlive $true -ListenerAlive $true -HasFinal $false -TelemetryAgeSeconds 1) -ceq 'RUNNING')
    Assert-Monitor ((Get-ConsoleActivityState -ControllerKnown $true -ControllerAlive $false -ListenerAlive $false -HasFinal $true) -ceq 'FINAL_RECEIPT_RECORDED')
}
$created=[DateTime]::Parse('2026-10-18T15:00:00Z').ToUniversalTime()
function New-MonitorProcess {param([int]$Id,[int]$Parent,[DateTime]$Created,[double]$Cpu=0)
    [pscustomobject]@{ProcessId=$Id;ParentProcessId=$Parent;CreationDate=$Created;Name='fixture.exe';KernelModeTime=0;UserModeTime=($Cpu*10000000);ReadTransferCount=0;WriteTransferCount=0;WorkingSetSize=1MB}}
Test-Monitor 'tree samples bind creation and exclude unrelated reused or older descendants' {
    $processes=@((New-MonitorProcess 1 0 $created),(New-MonitorProcess 2 1 $created.AddSeconds(1)),
        (New-MonitorProcess 3 2 $created.AddSeconds(2)),(New-MonitorProcess 4 1 $created.AddSeconds(-10)),(New-MonitorProcess 5 90 $created))
    Assert-Monitor (@(Select-ConsoleProcessTree -Processes $processes -RootId 1 -RootCreatedUtc $created).Count -eq 3)
    Assert-Monitor (@(Select-ConsoleProcessTree -Processes $processes -RootId 1 -RootCreatedUtc $created.AddSeconds(-1)).Count -eq 0)
}
Test-Monitor 'rates use stable process generations and normalized host capacity' {
    $first=Measure-ConsoleProcesses -Processes @((New-MonitorProcess 1 0 $created 1)) -Previous @{} -IntervalSeconds 0 -LogicalProcessors 12
    Assert-Monitor ($null -eq $first.cpuHostPercent)
    $next=Measure-ConsoleProcesses -Processes @((New-MonitorProcess 1 0 $created 7)) -Previous $first.previous -IntervalSeconds 1 -LogicalProcessors 12
    Assert-Monitor ($next.cpuHostPercent -eq 50 -and $next.workingSetMiB -eq 1)
    $reused=Measure-ConsoleProcesses -Processes @((New-MonitorProcess 1 0 $created.AddSeconds(2) 100)) -Previous $first.previous -IntervalSeconds 1 -LogicalProcessors 12
    Assert-Monitor ($reused.cpuHostPercent -eq 0)
}
Test-Monitor 'empty process snapshots yield no invented runner or QEMU activity' {
    $sample=Measure-ConsoleProcesses -Processes @() -Previous @{} -IntervalSeconds 10 -LogicalProcessors 12
    Assert-Monitor ($sample.processCount -eq 0 -and $sample.listenerCount -eq 0 -and $sample.qemuCount -eq 0)
}
Test-Monitor 'UTC conversion preserves typed timestamps under UK culture' {
    $culture=[Threading.Thread]::CurrentThread.CurrentCulture
    try {
        [Threading.Thread]::CurrentThread.CurrentCulture=[Globalization.CultureInfo]::GetCultureInfo('en-GB')
        foreach($value in @('2026-10-18T15:00:00Z',$created,[DateTimeOffset]::Parse('2026-10-18T16:00:00+01:00'))){
            Assert-Monitor ((ConvertTo-ConsoleUtc $value) -eq $created)
        }
    } finally {[Threading.Thread]::CurrentThread.CurrentCulture=$culture}
}
Test-Monitor 'file-backed snapshot handles UK JSON timestamps identity events and a live log writer' {
    $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    $root=Join-Path $temp ('runloc-monitor-'+[Guid]::NewGuid().ToString('N'))
    $writer=$null;$culture=[Threading.Thread]::CurrentThread.CurrentCulture
    try {
        [Threading.Thread]::CurrentThread.CurrentCulture=[Globalization.CultureInfo]::GetCultureInfo('en-GB')
        $lease=Join-Path $root 'lease';$fixture=Join-Path $root 'fixture'
        $inner=Join-Path $fixture 'runner/_work/j12345678/Evidence/outer/private/attempts/inner/private'
        [void][IO.Directory]::CreateDirectory($lease);[void][IO.Directory]::CreateDirectory($inner)
        [IO.File]::WriteAllText((Join-Path $lease 'lease.json'),(@{fixture=$fixture}|ConvertTo-Json))
        [IO.File]::WriteAllText((Join-Path $lease 'event-000001.json'),(@{kind='dispatched';utc='2026-10-18T15:00:00Z';data=@{runId=7}}|ConvertTo-Json))
        $records=@(
            @{event='start';operation='full-release';operationId=1;sequence=1;utc='2026-10-18T15:00:00Z';elapsedSeconds=0},
            @{event='start';operation='Assert-EzVmQemuPayloadIntegrity';operationId=2;sequence=2;utc='2026-10-18T15:00:01Z';elapsedSeconds=1},
            @{event='end';operation='Assert-EzVmQemuPayloadIntegrity';operationId=2;sequence=3;utc='2026-10-18T15:00:04Z';elapsedSeconds=4;durationSeconds=3},
            @{event='start';operation='Start-EzVmReadyInstance';operationId=3;sequence=4;utc='2026-10-18T15:00:05Z';elapsedSeconds=5},
            @{event='identity';sequence=5;utc='2026-10-18T15:00:06Z'})
        [IO.File]::WriteAllText((Join-Path $inner 'telemetry.jsonl'),(($records|ForEach-Object {$_|ConvertTo-Json -Compress}) -join [Environment]::NewLine)+[Environment]::NewLine)
        $stream=[IO.File]::Open((Join-Path $inner 'qualification.log'),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
        $writer=New-Object IO.StreamWriter($stream);$writer.AutoFlush=$true
        $writer.WriteLine('2026-10-18T15:00:05Z stdout EZVM010_STEP=guest_start; instance=ezvm010-source')
        $writer.WriteLine('2026-10-18T15:00:05Z stdout EZVM010_GUEST_CPUS=6; instance=ezvm010-source')
        $writer.WriteLine('2026-10-18T15:00:05Z stdout EZVM010_STEP=guest_ready; instance=ezvm010-source')
        $snapshot=Read-ConsoleLeaseSnapshot -LeaseRoot $lease -Processes @() -NowUtc $created.AddSeconds(10)
        Assert-Monitor ($snapshot.phaseSequence -eq 4 -and $snapshot.phaseAgeSeconds -eq 5 -and $snapshot.openOperationAgeSeconds -eq 5)
        Assert-Monitor ($snapshot.completedIntegrityChecks -eq 1 -and $snapshot.integrityCheckSeconds -eq 3)
        Assert-Monitor ($snapshot.guestReadyObserved -eq 1 -and $snapshot.guestCpuProofsObserved -eq 1 -and $snapshot.guestStage -ceq 'AUTHENTICATED_READY_OBSERVED')
        Assert-Monitor (-not $snapshot.listenerAlive -and $snapshot.runId -eq 7)
    }
    finally {
        [Threading.Thread]::CurrentThread.CurrentCulture=$culture
        if($null -ne $writer){$writer.Dispose()}
        $resolved=[IO.Path]::GetFullPath($root)
        if(-not $resolved.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or (Split-Path $resolved -Leaf) -cnotmatch '^runloc-monitor-[a-f0-9]{32}$'){throw 'monitor-test-cleanup-path-invalid'}
        if([IO.Directory]::Exists($resolved)){Remove-Item -LiteralPath $resolved -Recurse -Force}
    }
}
Test-Monitor 'actual controller exit survives delayed observation' {
    $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    $root=Join-Path $temp ('runloc-monitor-'+[Guid]::NewGuid().ToString('N'))
    $child=$null
    try {
        [void][IO.Directory]::CreateDirectory($root)
        $script=Join-Path $root 'exit.ps1'
        [IO.File]::WriteAllText($script,'Start-Sleep -Milliseconds 300; exit 7')
        $exe=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
        $child=Start-ConsoleControllerProcess -Executable $exe -Arguments ('-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "'+$script+'"') -WorkingDirectory $root -Stdout (Join-Path $root 'stdout.txt') -Stderr (Join-Path $root 'stderr.txt')
        Start-Sleep -Seconds 2
        $result=Complete-ConsoleControllerProcess -Process $child
        Assert-Monitor ($result.exitObserved -and $result.exitCode -eq 7)
    } finally {
        if($null -ne $child){$child.Dispose()}
        $resolved=[IO.Path]::GetFullPath($root)
        if(-not $resolved.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or (Split-Path $resolved -Leaf) -cnotmatch '^runloc-monitor-[a-f0-9]{32}$'){throw 'monitor-test-cleanup-path-invalid'}
        if([IO.Directory]::Exists($resolved)){Remove-Item -LiteralPath $resolved -Recurse -Force}
    }
}
Test-Monitor 'large IO deltas retain floating point overload and fractional CPU' {
    $process=New-MonitorProcess 1 0 $created 1
    $process.ReadTransferCount=[long]0; $process.WriteTransferCount=[long]0
    $first=Measure-ConsoleProcesses -Processes @($process) -Previous @{} -IntervalSeconds 0 -LogicalProcessors 12
    $process.ReadTransferCount=[long]4294967296; $process.WriteTransferCount=[long]3221225472
    $process.UserModeTime=[long]15000000
    $next=Measure-ConsoleProcesses -Processes @($process) -Previous $first.previous -IntervalSeconds 10 -LogicalProcessors 12
    Assert-Monitor ($next.readMiBPerSecond -eq 409.6 -and $next.writeMiBPerSecond -eq 307.2 -and $next.cpuHostPercent -eq 0.42)
}
Test-Monitor 'retained final receipt survives workspace disposal and rejects tampering' {
    $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    $root=Join-Path $temp ('runloc-monitor-'+[Guid]::NewGuid().ToString('N'))
    try {
        $inner=Join-Path $root 'private/qualification-evidence/outer/inner'
        [void][IO.Directory]::CreateDirectory($inner)
        [IO.File]::WriteAllText((Join-Path $root 'lease.json'),(@{fixture=(Join-Path $root 'disposed');candidateCommit='candidate'}|ConvertTo-Json))
        [IO.File]::WriteAllText((Join-Path $root 'event-000001.json'),(@{kind='final';utc='2026-10-18T15:00:00Z';data=@{passed=$true;elapsedSeconds=100}}|ConvertTo-Json))
        $events=@();1..24|ForEach-Object {$events+=@{kind='marker';name=('marker'+$_);value='PASS'}}
        1..8|ForEach-Object {$events+=@{kind='phase';name='guest_ready'};$events+=@{kind='guest-cpus';value='6'}}
        $receipt=@{leaseId='inner';supervisorLeaseId='outer';candidate=@{commit='candidate'};preflightOnly=$false;exitCode=0;events=$events;telemetry=@{operations=@(@{operation='Assert-EzVmQemuPayloadIntegrity';calls=292;inclusiveSeconds=6671.4;failedCalls=0})}}
        $path=Join-Path $inner 'receipt.json'
        [IO.File]::WriteAllText($path,($receipt|ConvertTo-Json -Depth 6))
        [IO.File]::WriteAllText((Join-Path $inner 'receipt-digest.json'),(@{file='receipt.json';sha256=(Get-FileHash $path -Algorithm SHA256).Hash.ToLowerInvariant()}|ConvertTo-Json))
        $snapshot=Read-ConsoleLeaseSnapshot -LeaseRoot $root -Processes @() -NowUtc $created
        Assert-Monitor ($snapshot.hasFinal -and -not $snapshot.listenerAlive -and $snapshot.observationSource -ceq 'retained-final-receipt')
        Assert-Monitor ($snapshot.markersObserved -eq 24 -and $snapshot.guestReadyObserved -eq 8 -and $snapshot.guestCpuProofsObserved -eq 8 -and $snapshot.finalExitCode -eq 0)
        Assert-Monitor ($snapshot.completedIntegrityChecks -eq 292 -and $snapshot.finalElapsedSeconds -eq 100)
        [IO.File]::AppendAllText($path,' ')
        $rejected=$false;try {$null=Read-ConsoleLeaseSnapshot -LeaseRoot $root -Processes @() -NowUtc $created}catch {$rejected=$_.Exception.Message -ceq 'monitor-receipt-digest-mismatch'}
        Assert-Monitor $rejected
        $receipt.candidate.commit='wrong-candidate'
        [IO.File]::WriteAllText($path,($receipt|ConvertTo-Json -Depth 6))
        [IO.File]::WriteAllText((Join-Path $inner 'receipt-digest.json'),(@{file='receipt.json';sha256=(Get-FileHash $path -Algorithm SHA256).Hash.ToLowerInvariant()}|ConvertTo-Json))
        $rejected=$false;try {$null=Read-ConsoleLeaseSnapshot -LeaseRoot $root -Processes @() -NowUtc $created}catch {$rejected=$_.Exception.Message -ceq 'monitor-receipt-identity-mismatch'}
        Assert-Monitor $rejected
    } finally {
        $resolved=[IO.Path]::GetFullPath($root)
        if(-not $resolved.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or (Split-Path $resolved -Leaf) -cnotmatch '^runloc-monitor-[a-f0-9]{32}$'){throw 'monitor-test-cleanup-path-invalid'}
        if([IO.Directory]::Exists($resolved)){Remove-Item -LiteralPath $resolved -Recurse -Force}
    }
}
Write-Host ('Monitor groups passed: '+$count)
