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
Write-Host ('Monitor groups passed: '+$count)
