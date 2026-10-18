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
$Host.UI.RawUI.WindowTitle='Runloc CI-PoC002 independent runner console'
Write-Host 'This console is owned by Windows Explorer, independently of Codex.'
Write-Host 'GitHub runner: native Windows host. EzVM guest allocation: 6 vCPUs.'
Write-Host 'Keep this console and the PC running. Closing Codex is safe; closing this console can interrupt the job.'
if($plan.mode -ceq 'Monitor'){Write-Host 'READ-ONLY MONITOR: this window starts no runner, guest or GitHub job. Recorded timestamps may be from an interrupted attempt.'}
$child=$null
if ($plan.mode -ceq 'Start') {
    if ($plan.controllerRoot -cne [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')) -or
        $plan.controllerCommit -cnotmatch '^[a-f0-9]{40}$' -or $plan.workflowRef -cnotmatch '^ci-poc-002-[a-f0-9]{40}$') { throw 'console-start-source-invalid' }
    Import-PilotNative
    $arguments=@('-NoLogo','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'Invoke-OneJobRunner.ps1'),
        '-Action','Start','-BackingRoot',$plan.backingRoot,'-ExpectedControllerCommit',$plan.controllerCommit,'-WorkflowRef',$plan.workflowRef,
        '-Mode',$plan.qualificationMode)
    $command=(@($arguments|ForEach-Object {[RunlocPoc.OwnedProcess]::QuoteArgument([string]$_)}) -join ' ')
    $child=Start-Process -FilePath (Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe') -ArgumentList $command -NoNewWindow -PassThru -WorkingDirectory $plan.controllerRoot -RedirectStandardOutput (Join-Path $state 'controller.stdout.log') -RedirectStandardError (Join-Path $state 'controller.stderr.log')
    Write-PilotNewJson -Path (Join-Path $state 'controller-started.json') -Value @{processId=$child.Id;createdUtc=$child.StartTime.ToUniversalTime().ToString('o')}
}
$last=''
do {
    $leases=@(Get-ChildItem -LiteralPath $plan.backingRoot -Directory -Filter 'runloc-whpx-*'|Sort-Object LastWriteTimeUtc -Descending)
    if ($null -ne $child) {
        $stdout=Join-Path $state 'controller.stdout.log'
        $match=@(Get-Content -LiteralPath $stdout -ErrorAction SilentlyContinue|Where-Object {$_ -cmatch '^RUNLOC_RUNNER_LEASE='})
        $leases=@($leases|Where-Object {$match -ccontains ('RUNLOC_RUNNER_LEASE='+$_.FullName)})
    }
    if ($leases.Count) {
        $lease=$leases[0]
        try {
        $eventFile=@(Get-ChildItem -LiteralPath $lease.FullName -File -Filter 'event-*.json'|Sort-Object Name|Select-Object -Last 1)
        if ($eventFile.Count) {
            $event=[IO.File]::ReadAllText($eventFile[0].FullName)|ConvertFrom-Json
            if ($event.kind -cmatch '^[a-z-]+$') {
                $line=$lease.Name+' : '+$event.kind
                if ($line -cne $last) { Write-Host ([DateTime]::Now.ToString('HH:mm:ss')+' '+$line+'; recordedUTC='+$event.utc);$last=$line }
                if ($event.kind -ceq 'final') { Write-Host ($event.data|ConvertTo-Json -Compress) }
            }
        }
            $owner=[IO.File]::ReadAllText((Join-Path $lease.FullName 'lease.json'))|ConvertFrom-Json
            $work=Join-Path $owner.fixture 'runner/_work'
            $telemetry=@()
            if ([IO.Directory]::Exists($work)) {
                foreach($jobRoot in @(Get-ChildItem -LiteralPath $work -Directory -Filter 'j????????'|Select-Object -First 4)) {
                    $evidence=Join-Path $jobRoot.FullName 'Evidence'
                    if (-not [IO.Directory]::Exists($evidence)) { continue }
                    foreach($outer in @(Get-ChildItem -LiteralPath $evidence -Directory|Select-Object -First 4)) {
                        $attempts=Join-Path $outer.FullName 'private/attempts'
                        if (-not [IO.Directory]::Exists($attempts)) { continue }
                        foreach($inner in @(Get-ChildItem -LiteralPath $attempts -Directory|Select-Object -First 4)) {
                            $path=Join-Path $inner.FullName 'private/telemetry.jsonl'
                            if ([IO.File]::Exists($path)) { $telemetry+=Get-Item -LiteralPath $path }
                        }
                    }
                }
            }
            if ($telemetry.Count) {
                $latest=$telemetry|Sort-Object LastWriteTimeUtc -Descending|Select-Object -First 1
                $phase=Get-Content -LiteralPath $latest.FullName -Tail 1|ConvertFrom-Json
                if ($phase.operation -cmatch '^[A-Za-z0-9-]+$' -and $phase.event -cmatch '^[a-z-]+$') {
                    Write-Host ('Telemetry '+$phase.sequence+': '+$phase.event+' '+$phase.operation+'; elapsed='+[Math]::Round($phase.elapsedSeconds,1)+'s; recordedUTC='+$phase.utc)
                }
            }
        }
        catch { Write-Host 'Phase snapshot unavailable during write/cleanup; qualification outcome still comes from its receipt.' }
    }
    if ($null -eq $child) { Write-Host ('Host QEMU processes now: '+@(Get-Process -Name 'qemu-system-x86_64' -ErrorAction SilentlyContinue).Count+' (observation only). No new job started. Ctrl+C stops monitoring.') }
    else { $child.Refresh(); if($child.HasExited){break} }
    Start-Sleep -Seconds 10
} while ($true)
if ($null -ne $child) {
    $child.WaitForExit()
    Write-PilotNewJson -Path (Join-Path $state 'controller-ended.json') -Value @{exitCode=$child.ExitCode;endedUtc=[DateTime]::UtcNow.ToString('o')}
    Write-Host ('Controller exit code: '+$child.ExitCode+'. Inspect the final receipt; a zero runner exit alone is not qualification.')
}
