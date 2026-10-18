#requires -Version 5.1
[CmdletBinding()]param(
    [Parameter(Mandatory=$true)][string]$PlanPath,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{64}$')][string]$PlanSha256
)
$ErrorActionPreference='Stop'
$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
$PlanPath=Assert-PilotPath -Path $PlanPath -File
if ((Get-PilotDigest -Path $PlanPath) -cne $PlanSha256) { throw 'console-plan-changed' }
$plan=[IO.File]::ReadAllText($PlanPath)|ConvertFrom-Json
$state=Assert-PilotPath -Path $plan.stateRoot
if ([IO.Path]::GetDirectoryName($PlanPath) -cne $state -or $plan.schemaVersion -ne 1 -or
    @('Start','Monitor','Probe') -cnotcontains $plan.mode -or
    @('qualification','probe','no-job') -cnotcontains $plan.qualificationMode) { throw 'console-plan-invalid' }
$me=Get-CimInstance Win32_Process -Filter ('ProcessId='+$PID)
$parent=Get-CimInstance Win32_Process -Filter ('ProcessId='+$me.ParentProcessId)
if ($null -eq $parent -or $parent.Name -cne 'explorer.exe' -or $parent.CreationDate -ge $me.CreationDate) { throw 'independent-explorer-parent-required' }
Write-PilotNewJson -Path (Join-Path $state 'console-ready.json') -Value @{
    schemaVersion=1;processId=$PID;createdUtc=$me.CreationDate.ToUniversalTime().ToString('o');parentId=$parent.ProcessId;
    parentName=$parent.Name;parentCreatedUtc=$parent.CreationDate.ToUniversalTime().ToString('o');planSha256=$PlanSha256;mode=$plan.mode}
if ($plan.mode -ceq 'Probe') {
    for($i=0;$i -lt 15;$i++) {
        [IO.File]::WriteAllText((Join-Path $state 'heartbeat.txt'),[DateTime]::UtcNow.ToString('o'))
        if ([IO.File]::Exists((Join-Path $state 'stop.request'))) { break }
        Start-Sleep -Seconds 1
    }
    Write-PilotNewJson -Path (Join-Path $state 'probe-ended.json') -Value @{exitCode=0;processId=$PID}
    exit 0
}
$Host.UI.RawUI.WindowTitle='Runloc CI-PoC002 independent console - '+$plan.mode+' '+$plan.qualificationMode
Write-Host 'This console is owned by Windows Explorer, independently of Codex.'
Write-Host 'GitHub runner: native Windows host. EzVM guest allocation: 6 vCPUs.'
Write-Host 'Keep this console and the PC running. Closing Codex is safe; closing this console can interrupt the job.'
if($plan.mode -ceq 'Monitor'){Write-Host 'READ-ONLY MONITOR: this window starts no runner, guest or GitHub job. Recorded timestamps may be from an interrupted attempt.'}
$child=$null
. (Join-Path $PSScriptRoot 'Console.Monitor.ps1')
if ($plan.mode -ceq 'Start') {
    if ($plan.controllerRoot -cne [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')) -or
        $plan.controllerCommit -cnotmatch '^[a-f0-9]{40}$' -or $plan.workflowRef -cnotmatch '^ci-poc-002-[a-f0-9]{40}$') { throw 'console-start-source-invalid' }
    Import-PilotNative
    $arguments=@('-NoLogo','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'Invoke-OneJobRunner.ps1'),
        '-Action','Start','-BackingRoot',$plan.backingRoot,'-ExpectedControllerCommit',$plan.controllerCommit,'-WorkflowRef',$plan.workflowRef,
        '-Mode',$plan.qualificationMode)
    $command=(@($arguments|ForEach-Object {[RunlocPoc.OwnedProcess]::QuoteArgument([string]$_)}) -join ' ')
    $child=Start-ConsoleControllerProcess -Executable (Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe') -Arguments $command -WorkingDirectory $plan.controllerRoot -Stdout (Join-Path $state 'controller.stdout.log') -Stderr (Join-Path $state 'controller.stderr.log')
    Write-PilotNewJson -Path (Join-Path $state 'controller-started.json') -Value @{processId=$child.Id;createdUtc=$child.StartTime.ToUniversalTime().ToString('o')}
}
# The console remains observational; failures here never qualify or cancel work.
$lastSequence='';$lastStatus='';$lastIdlePrint=[DateTime]::MinValue
$previous=@{};$sampleClock=[Diagnostics.Stopwatch]::StartNew();$lastSample=0.0
$memoryMiB=$null;$lastMemory=[DateTime]::MinValue
$metricsPath=Join-Path $state 'monitor.jsonl'
$metricsLimitNotified=$false
Write-Host ('Private structured metrics: '+$metricsPath)
Write-Host 'CPU is sampled percentage of total host capacity for the controller process tree; exited processes between samples can be missed.'
Write-Host 'No new phase event means quiet telemetry, not fresh progress. Final qualification comes only from its receipt.'
do {
    try {
        $now=[DateTime]::UtcNow
        $processes=@(Get-CimInstance Win32_Process -Property ProcessId,ParentProcessId,Name,CreationDate,KernelModeTime,UserModeTime,WorkingSetSize,ReadTransferCount,WriteTransferCount)
        $tree=@();$controllerAlive=$false
        if($null -ne $child){
            $child.Refresh();$controllerAlive=-not $child.HasExited
            if($controllerAlive){$tree=@(Select-ConsoleProcessTree -Processes $processes -RootId $child.Id -RootCreatedUtc $child.StartTime.ToUniversalTime())}
        }
        $leases=@(Get-ChildItem -LiteralPath $plan.backingRoot -Directory -Filter 'runloc-whpx-*'|Sort-Object LastWriteTimeUtc -Descending)
        if($null -ne $child){
            $stdout=Join-Path $state 'controller.stdout.log';$matchesLease=@()
            if([IO.File]::Exists($stdout) -and (Get-Item -LiteralPath $stdout).Length -le 1MB){$matchesLease=@(Get-Content -LiteralPath $stdout|Where-Object {$_ -cmatch '^RUNLOC_RUNNER_LEASE='})}
            $leases=@($leases|Where-Object {$matchesLease -ccontains ('RUNLOC_RUNNER_LEASE='+$_.FullName)})
        }
        $snapshot=$null;$activity='STARTING_NO_LEASE_YET'
        if($leases.Count){
            $snapshot=Read-ConsoleLeaseSnapshot -LeaseRoot $leases[0].FullName -Processes $processes -NowUtc $now
            $activity=Get-ConsoleActivityState -ControllerKnown ($null -ne $child) -ControllerAlive $controllerAlive -ListenerAlive $snapshot.listenerAlive -HasFinal $snapshot.hasFinal -TelemetryAgeSeconds $snapshot.phaseAgeSeconds
            if($null -eq $child -and $snapshot.listenerAlive){$tree=@(Select-ConsoleProcessTree -Processes $processes -RootId $snapshot.listenerProcessId -RootCreatedUtc (ConvertTo-ConsoleUtc $snapshot.listenerCreatedUtc))}
        }
        elseif($null -eq $child){$activity='NO_ACTIVE_RUN_NO_EVIDENCE'}
        if(($now-$lastMemory).TotalSeconds -ge 60){
            $os=Get-CimInstance Win32_OperatingSystem -Property FreePhysicalMemory
            $memoryMiB=[Math]::Round([double]$os.FreePhysicalMemory/1024,0);$lastMemory=$now
        }
        $elapsed=$sampleClock.Elapsed.TotalSeconds
        $interval=if($lastSample -eq 0){0}else{$elapsed-$lastSample}
        $resource=Measure-ConsoleProcesses -Processes $tree -Previous $previous -IntervalSeconds $interval -LogicalProcessors ([Environment]::ProcessorCount)
        $previous=$resource.previous;$lastSample=$elapsed
        $metric=[ordered]@{schemaVersion=1;observedUtc=$now.ToString('o');activity=$activity;consoleMode=$plan.mode;
            controllerAlive=$controllerAlive;consoleElapsedSeconds=[Math]::Round($elapsed,1);hostFreeMemoryMiB=$memoryMiB;
            sampledTreeProcessCount=$resource.processCount;sampledTreeListenerCount=$resource.listenerCount;sampledTreeQemuCount=$resource.qemuCount;
            sampledTreeCpuHostPercent=$resource.cpuHostPercent;sampledTreeWorkingSetMiB=$resource.workingSetMiB;
            sampledTreeReadMiBPerSecond=$resource.readMiBPerSecond;sampledTreeWriteMiBPerSecond=$resource.writeMiBPerSecond;
            hostQemuProcessCount=@($processes|Where-Object {$_.Name -ceq 'qemu-system-x86_64.exe'}).Count;snapshot=$snapshot}
        try {
            $serialized=($metric|ConvertTo-Json -Depth 10 -Compress)+[Environment]::NewLine
            $size=if([IO.File]::Exists($metricsPath)){(Get-Item -LiteralPath $metricsPath).Length}else{0}
            if($size+[Text.Encoding]::UTF8.GetByteCount($serialized) -le 4MB){[IO.File]::AppendAllText($metricsPath,$serialized,(New-Object Text.UTF8Encoding($false)))}
            elseif(-not $metricsLimitNotified){Write-Host 'PRIVATE_METRICS_LOG_LIMIT_REACHED; live display and qualification continue.';$metricsLimitNotified=$true}
        } catch { Write-Host 'METRICS_LOG_WRITE_FAILED: observation only; controller continues.' }
        $statusKey=$activity+'/'+$(if($null -ne $snapshot){$snapshot.leaseId}else{''})
        if($statusKey -cne $lastStatus){
            Write-Host ('STATE '+$activity+' at '+[DateTime]::Now.ToString('HH:mm:ss'))
            if($null -ne $snapshot){Write-Host ('Lease='+$snapshot.leaseId+' runner='+$snapshot.runnerId+' run='+$snapshot.runId+' lastEvent='+$snapshot.lastEvent+' eventUTC='+$snapshot.lastEventUtc)}
            $lastStatus=$statusKey
        }
        $live=$controllerAlive -or ($null -ne $snapshot -and $snapshot.listenerAlive)
        if($null -ne $snapshot -and $snapshot.hasFinal -and $lastSequence -cne 'final-summary'){
            $receiptExit=if($null -eq $snapshot.finalExitCode){'UNAVAILABLE'}else{[string]$snapshot.finalExitCode}
            Write-Host ('FINAL RETAINED HOST RESULT hostPassed='+$snapshot.finalPassed+' receiptExit='+$receiptExit+' supervisedSeconds='+$snapshot.finalElapsedSeconds+' markers='+$snapshot.markersObserved+'/24 READY='+$snapshot.guestReadyObserved+'/8 CPU6='+$snapshot.guestCpuProofsObserved+'/8 source='+$snapshot.observationSource+'. Retained host result; current process state is shown separately.')
            $lastSequence='final-summary'
        }
        if($null -ne $snapshot){
            $sequenceKey=$snapshot.leaseId+'/'+$snapshot.phaseSequence
            if($sequenceKey -cne $lastSequence -and $null -ne $snapshot.phaseSequence){
                $label=if($live){'PHASE EVENT'}else{'RETAINED EVENT - NOT LIVE'}
                Write-Host ($label+' seq='+$snapshot.phaseSequence+' '+$snapshot.phaseEvent+' '+$snapshot.phaseOperation+' recordedUTC='+$snapshot.phaseRecordedUtc)
                $lastSequence=$sequenceKey
            }
        }
        if($live -or ($now-$lastIdlePrint).TotalSeconds -ge 60){
            $phaseText=if($null -ne $snapshot){' phaseAge='+$snapshot.phaseAgeSeconds+'s open='+$snapshot.openOperation+' openAge='+$snapshot.openOperationAgeSeconds+'s guest='+$snapshot.guestStage+' markers='+$snapshot.markersObserved+'/24 READY='+$snapshot.guestReadyObserved+'/8 CPU6='+$snapshot.guestCpuProofsObserved+'/8 integrityChecks='+$snapshot.completedIntegrityChecks+' integritySeconds='+$snapshot.integrityCheckSeconds+' phaseFailures='+$snapshot.telemetryFailures}else{''}
            Write-Host ([DateTime]::Now.ToString('HH:mm:ss')+' HEARTBEAT '+$activity+' elapsed='+[Math]::Round($elapsed,1)+'s treeProcesses='+$resource.processCount+' listener='+$resource.listenerCount+' QEMU='+$resource.qemuCount+' hostCPU%='+$resource.cpuHostPercent+' RSSMiB='+$resource.workingSetMiB+' readMiB/s='+$resource.readMiBPerSecond+' writeMiB/s='+$resource.writeMiBPerSecond+' freeRAMMiB='+$memoryMiB+$phaseText)
            $lastIdlePrint=$now
        }
    }
    catch {
        Write-Host ('MONITOR_SNAPSHOT_UNAVAILABLE at '+[DateTime]::Now.ToString('HH:mm:ss')+' type='+$_.Exception.GetType().Name+' line='+$_.InvocationInfo.ScriptLineNumber+'; controller continues. No progress is inferred.')
    }
    if($null -ne $child){$child.Refresh();if($child.HasExited){break}}
    Start-Sleep -Seconds 10
} while($true)
if($null -ne $child){
    $ended=Complete-ConsoleControllerProcess -Process $child
    Write-PilotNewJson -Path (Join-Path $state 'controller-ended.json') -Value @{exitCode=$ended.exitCode;exitObserved=$ended.exitObserved;endedUtc=[DateTime]::UtcNow.ToString('o')}
    $exitText=if($ended.exitObserved){[string]$ended.exitCode}else{'UNKNOWN - actual exit unavailable'}
    Write-Host ('STOPPED. Actual controller exit='+$exitText+'. No further live progress. Final qualification requires the complete receipt and cleanup.')
    Write-Host ('Private diagnostics: '+$state)
}
