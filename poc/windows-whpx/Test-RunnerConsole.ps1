#requires -Version 5.1
# Opt-in interactive desktop qualification. Never registers or dispatches a job.
[CmdletBinding()]param([Parameter(Mandatory=$true)][string]$EvidenceParent)
$ErrorActionPreference='Stop'
$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
Import-PilotNative
$parent=Assert-PilotPath -Path $EvidenceParent
$root=Join-Path $parent ('console-test-'+[Guid]::NewGuid().ToString('N'))
[RunlocPoc.OwnedProcess]::CreateNewDirectory($root)
Set-PilotPrivateDirectory -Path $root
$entry=Join-Path $PSScriptRoot 'Open-RunnerConsole.ps1'
$parentScript=Join-Path $root 'parent.ps1'
$text="& '"+$entry.Replace("'","''")+"' -Mode Probe -BackingRoot '"+$root.Replace("'","''")+"'"+[Environment]::NewLine+'Start-Sleep -Seconds 60'
[IO.File]::WriteAllText($parentScript,$text)
$job=$null;$state=$null;$probe=$null
try {
    $job=New-Object RunlocPoc.OwnedProcess((Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'),
        [string[]]@('-NoLogo','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$parentScript),$root,$root,(Join-Path $root 'parent.log'),[long]1048576)
    $clock=[Diagnostics.Stopwatch]::StartNew()
    while ($null -eq $state -and $clock.Elapsed.TotalSeconds -lt 35) {
        foreach($line in $job.Drain()) { if($line.Text.StartsWith('RUNLOC_CONSOLE_STATE=',[StringComparison]::Ordinal)) { $state=$line.Text.Substring('RUNLOC_CONSOLE_STATE='.Length) } }
        if($job.HasExited -and $null -eq $state){throw 'console-launch-parent-exited'}
        Start-Sleep -Milliseconds 100
    }
    if ($null -eq $state) { throw 'console-launch-unconfirmed' }
    $state=Assert-PilotPath -Path $state
    $ready=[IO.File]::ReadAllText((Join-Path $state 'console-ready.json'))|ConvertFrom-Json
    if($ready.parentName -cne 'explorer.exe'){throw 'console-still-owned-by-launcher'}
    $probe=[Diagnostics.Process]::GetProcessById([int]$ready.processId)
    $null=$probe.Handle # Hold the actual process object, not a later numeric PID lookup.
    if([Math]::Abs(($probe.StartTime.ToUniversalTime()-[DateTime]::Parse($ready.createdUtc).ToUniversalTime()).TotalMilliseconds) -ge 1){throw 'probe-process-creation-mismatch'}
    $before=[IO.File]::GetLastWriteTimeUtc((Join-Path $state 'heartbeat.txt'))
    $job.Terminate()
    $stop=[Diagnostics.Stopwatch]::StartNew()
    while((-not $job.HasExited -or $job.ActiveProcesses -ne 0) -and $stop.Elapsed.TotalSeconds -lt 5){Start-Sleep -Milliseconds 100}
    if(-not $job.HasExited -or $job.ActiveProcesses -ne 0){throw 'parent-job-not-empty'}
    Start-Sleep -Seconds 3
    $after=[IO.File]::GetLastWriteTimeUtc((Join-Path $state 'heartbeat.txt'))
    if($after -le $before){throw 'console-did-not-survive-parent-job-termination'}
    [IO.File]::WriteAllText((Join-Path $state 'stop.request'),'stop')
    $stop.Restart()
    while(-not [IO.File]::Exists((Join-Path $state 'probe-ended.json')) -and $stop.Elapsed.TotalSeconds -lt 10){Start-Sleep -Milliseconds 100}
    $end=[IO.File]::ReadAllText((Join-Path $state 'probe-ended.json'))|ConvertFrom-Json
    if($end.exitCode -ne 0 -or $end.processId -ne $ready.processId){throw 'probe-clean-exit-unconfirmed'}
    if(-not $probe.WaitForExit(10000) -or $probe.ExitCode -ne 0){throw 'probe-actual-exit-unconfirmed'}
    Write-PilotNewJson -Path (Join-Path $root 'result.json') -Value @{schemaVersion=1;test='independent-console-survives-launcher-job-termination';
        passed=$true;desktopParentName=$ready.parentName;parentOwnedProcessesAfter=0;heartbeatAdvancedAfterParentDeath=$true;
        probeExitCode=$probe.ExitCode;actualProbeExitObserved=$true;liveRegistrationOrDispatch=$false}
    Write-Host ('PASS independent console; evidence='+$root)
}
finally {
    if($null -ne $state -and -not [IO.File]::Exists((Join-Path $state 'stop.request'))){[IO.File]::WriteAllText((Join-Path $state 'stop.request'),'stop')}
    if($null -ne $job){$job.Dispose()}
    if($null -ne $probe){$probe.Dispose()}
}
