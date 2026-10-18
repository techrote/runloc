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
Write-Host ('Monitor groups passed: '+$count)
