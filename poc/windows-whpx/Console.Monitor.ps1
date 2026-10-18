#requires -Version 5.1
# Observational metrics only: none of these values can qualify a run.
function Get-ConsoleActivityState {
    param([bool]$ControllerKnown,[bool]$ControllerAlive,[bool]$ListenerAlive,[bool]$HasFinal,
        [double]$TelemetryAgeSeconds=-1)
    if($HasFinal){return 'FINAL_RECEIPT_RECORDED'}
    if($ControllerKnown -and -not $ControllerAlive){return 'INTERRUPTED_NO_FINAL_RECEIPT'}
    if($ControllerAlive -or $ListenerAlive){
        if($TelemetryAgeSeconds -gt 120){return 'RUNNING_TELEMETRY_QUIET'}
        return 'RUNNING'
    }
    return 'NO_ACTIVE_RUN_RETAINED_EVIDENCE'
}
function Select-ConsoleProcessTree {
    param([object[]]$Processes,[int]$RootId,[DateTime]$RootCreatedUtc)
    $roots=@($Processes|Where-Object {$_.ProcessId -eq $RootId -and
        [Math]::Abs(($_.CreationDate.ToUniversalTime()-$RootCreatedUtc.ToUniversalTime()).TotalMilliseconds) -lt 1})
    if($roots.Count -ne 1){return @()}
    $tree=New-Object 'Collections.Generic.List[object]'
    $tree.Add($roots[0])
    for($index=0;$index -lt $tree.Count;$index++){
        $parent=$tree[$index]
        foreach($candidate in @($Processes|Where-Object {$_.ParentProcessId -eq $parent.ProcessId -and $_.ProcessId -ne $parent.ProcessId -and
            $_.CreationDate.ToUniversalTime() -ge $parent.CreationDate.ToUniversalTime()})){
            if(@($tree|Where-Object {$_.ProcessId -eq $candidate.ProcessId}).Count -eq 0){$tree.Add($candidate)}
        }
    }
    return $tree.ToArray()
}
function Measure-ConsoleProcesses {
    param([object[]]$Processes,[hashtable]$Previous,[double]$IntervalSeconds,[int]$LogicalProcessors)
    $next=@{};$cpuDelta=0.0;$readDelta=0.0;$writeDelta=0.0;$rss=0.0
    foreach($process in $Processes){
        $key=[string]$process.ProcessId+'/'+$process.CreationDate.ToUniversalTime().ToString('o')
        $cpu=([double]$process.KernelModeTime+[double]$process.UserModeTime)/10000000
        $read=[double]$process.ReadTransferCount;$write=[double]$process.WriteTransferCount
        if($Previous.ContainsKey($key)){
            $cpuDelta+=[Math]::Max(0,$cpu-$Previous[$key].cpu)
            $readDelta+=[Math]::Max(0,$read-$Previous[$key].read)
            $writeDelta+=[Math]::Max(0,$write-$Previous[$key].write)
        }
        $next[$key]=@{cpu=$cpu;read=$read;write=$write}
        $rss+=[double]$process.WorkingSetSize
    }
    $percent=$null;$readRate=$null;$writeRate=$null
    if($IntervalSeconds -gt 0 -and $LogicalProcessors -gt 0){
        $percent=[Math]::Round(100*$cpuDelta/$IntervalSeconds/$LogicalProcessors,2)
        $readRate=[Math]::Round($readDelta/$IntervalSeconds/1MB,2)
        $writeRate=[Math]::Round($writeDelta/$IntervalSeconds/1MB,2)
    }
    return @{previous=$next;cpuHostPercent=$percent;readMiBPerSecond=$readRate;writeMiBPerSecond=$writeRate;
        workingSetMiB=[Math]::Round($rss/1MB,1);processCount=$Processes.Count;
        listenerCount=@($Processes|Where-Object {$_.Name -ceq 'Runner.Listener.exe'}).Count;
        qemuCount=@($Processes|Where-Object {$_.Name -ceq 'qemu-system-x86_64.exe'}).Count}
}
function Read-ConsoleLeaseSnapshot {
    param([string]$LeaseRoot,[object[]]$Processes,[DateTime]$NowUtc)
    $events=@(Get-ChildItem -LiteralPath $LeaseRoot -File -Filter 'event-*.json'|Sort-Object Name|Select-Object -Last 1000|
        ForEach-Object {[IO.File]::ReadAllText($_.FullName)|ConvertFrom-Json})
    $final=@($events|Where-Object {$_.kind -ceq 'final'})
    $listener=@($events|Where-Object {$_.kind -ceq 'listener-started'}|Select-Object -Last 1)
    $listenerAlive=$false
    $listenerProcess=@()
    if($listener.Count){
        # OwnedProcess.CreatedUtc precedes CreateProcess, so use a bounded
        # creation window plus exact PID/name for this observational snapshot.
        $began=[DateTime]::Parse($listener[0].data.createdUtc).ToUniversalTime()
        $listenerProcess=@($Processes|Where-Object {$_.ProcessId -eq $listener[0].data.processId -and $_.Name -ceq 'Runner.Listener.exe' -and
            $_.CreationDate.ToUniversalTime() -ge $began -and $_.CreationDate.ToUniversalTime() -le $began.AddSeconds(5)})
        $listenerAlive=$listenerProcess.Count -eq 1
    }
    $last=$events|Select-Object -Last 1
    $registered=$events|Where-Object {$_.kind -ceq 'registered'}|Select-Object -Last 1
    $dispatched=$events|Where-Object {$_.kind -ceq 'dispatched'}|Select-Object -Last 1
    $snapshot=[ordered]@{leaseId=(Split-Path $LeaseRoot -Leaf);lastEvent=$null;lastEventUtc=$null;runnerId=$null;runId=$null;
        hasFinal=($final.Count -gt 0);listenerAlive=$listenerAlive;listenerProcessId=$null;listenerCreatedUtc=$null;phaseSequence=$null;phaseEvent=$null;phaseOperation=$null;
        phaseRecordedUtc=$null;phaseAgeSeconds=-1;phaseElapsedSeconds=$null;openOperation=$null;openOperationAgeSeconds=$null;
        completedIntegrityChecks=0;integrityCheckSeconds=0;telemetryFailures=0;markersObserved=0;guestReadyObserved=0;guestCpuProofsObserved=0;
        guestStartsObserved=0;baseBuildStartedObserved=$false;guestStage='GUEST_STAGE_UNOBSERVED'}
    if($null -ne $last){$snapshot.lastEvent=$last.kind;$snapshot.lastEventUtc=$last.utc}
    if($null -ne $registered){$snapshot.runnerId=$registered.data.runnerId}
    if($null -ne $dispatched){$snapshot.runId=$dispatched.data.runId}
    if($listenerAlive){$snapshot.listenerProcessId=$listenerProcess[0].ProcessId;$snapshot.listenerCreatedUtc=$listenerProcess[0].CreationDate.ToUniversalTime().ToString('o')}
    $owner=[IO.File]::ReadAllText((Join-Path $LeaseRoot 'lease.json'))|ConvertFrom-Json
    $work=Join-Path $owner.fixture 'runner/_work';$paths=@()
    if([IO.Directory]::Exists($work)){
        foreach($jobRoot in @(Get-ChildItem -LiteralPath $work -Directory -Filter 'j????????'|Select-Object -First 4)){
            $evidence=Join-Path $jobRoot.FullName 'Evidence'
            if(-not [IO.Directory]::Exists($evidence)){continue}
            foreach($outer in @(Get-ChildItem -LiteralPath $evidence -Directory|Select-Object -First 4)){
                $attempts=Join-Path $outer.FullName 'private/attempts'
                if(-not [IO.Directory]::Exists($attempts)){continue}
                foreach($inner in @(Get-ChildItem -LiteralPath $attempts -Directory|Select-Object -First 4)){
                    $path=Join-Path $inner.FullName 'private/telemetry.jsonl'
                    if([IO.File]::Exists($path)){$paths+=Get-Item -LiteralPath $path}
                }
            }
        }
    }
    if($paths.Count){
        $latest=$paths|Sort-Object LastWriteTimeUtc -Descending|Select-Object -First 1
        if($latest.Length -gt 8MB){throw 'monitor-telemetry-size-bound'}
        $records=@(Get-Content -LiteralPath $latest.FullName|ForEach-Object {$_|ConvertFrom-Json})
        $phase=$records|Where-Object {$null -ne $_.PSObject.Properties['operation']}|Select-Object -Last 1
        if($null -eq $phase){return $snapshot}
        if($phase.operation -cmatch '^[A-Za-z0-9-]+$' -and $phase.event -cmatch '^[a-z-]+$'){
            $snapshot.phaseSequence=$phase.sequence;$snapshot.phaseEvent=$phase.event;$snapshot.phaseOperation=$phase.operation
            $snapshot.phaseRecordedUtc=$phase.utc;$snapshot.phaseElapsedSeconds=$phase.elapsedSeconds
            $snapshot.phaseAgeSeconds=[Math]::Round([Math]::Max(0,($NowUtc-[DateTime]::Parse($phase.utc).ToUniversalTime()).TotalSeconds),1)
        }
        $closed=@($records|Where-Object {$_.event -cin @('end','failure')}|ForEach-Object {$_.operationId})
        $open=$records|Where-Object {$_.event -ceq 'start' -and $closed -cnotcontains $_.operationId}|Select-Object -Last 1
        if($null -ne $open -and $open.operation -cmatch '^[A-Za-z0-9-]+$'){
            $snapshot.openOperation=$open.operation;$snapshot.openOperationAgeSeconds=[Math]::Round([Math]::Max(0,($NowUtc-[DateTime]::Parse($open.utc).ToUniversalTime()).TotalSeconds),1)
        }
        $integrity=@($records|Where-Object {$_.event -ceq 'end' -and $_.operation -ceq 'Assert-EzVmQemuPayloadIntegrity'})
        $snapshot.completedIntegrityChecks=$integrity.Count
        if($integrity.Count){$snapshot.integrityCheckSeconds=[Math]::Round(($integrity|Measure-Object durationSeconds -Sum).Sum,1)}
        $snapshot.telemetryFailures=@($records|Where-Object {$_.event -ceq 'failure'}).Count
        $log=Join-Path $latest.DirectoryName 'qualification.log'
        if([IO.File]::Exists($log) -and (Get-Item -LiteralPath $log).Length -le 32MB){
            # PowerShell's reader shares with the live writer; ReadAllLines'
            # FileShare.Read would conflict with the qualification log handle.
            $lines=@(Get-Content -LiteralPath $log)
            $snapshot.guestStage='GUEST_START_NOT_OBSERVED'
            $snapshot.markersObserved=@($lines|Where-Object {$_ -cmatch ' EZVM01[012]_(REAL_[A-Z_]+|WHPX_EXECUTION)=PASS$'}).Count
            $snapshot.guestReadyObserved=@($lines|Where-Object {$_ -cmatch ' EZVM010_STEP=guest_ready;'}).Count
            $snapshot.guestCpuProofsObserved=@($lines|Where-Object {$_ -cmatch ' EZVM010_GUEST_CPUS=6;'}).Count
            $snapshot.guestStartsObserved=@($lines|Where-Object {$_ -cmatch ' EZVM010_STEP=guest_start;'}).Count
            $snapshot.baseBuildStartedObserved=@($lines|Where-Object {$_ -cmatch ' EZVM010_STEP=base_build_started;'}).Count -gt 0
            if($snapshot.guestReadyObserved -gt 0){$snapshot.guestStage='AUTHENTICATED_READY_OBSERVED'}
            elseif($snapshot.guestStartsObserved -gt 0){$snapshot.guestStage='GUEST_START_ATTEMPTED_NO_READY'}
            elseif($snapshot.baseBuildStartedObserved){$snapshot.guestStage='BASE_BUILD_PHASE_STARTED_NO_READY'}
        }
    }
    return $snapshot
}
