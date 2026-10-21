#requires -Version 5.1
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'TimerProbe.Common.ps1')
$default=@(Get-TimerProbeArguments -Hpet default -Image 'C:\owned\image.qcow2' -FirmwareCode 'C:\owned\code.fd' -FirmwareVariables 'C:\owned\vars.fd' -SerialLog 'C:\owned\serial.log')
$off=@(Get-TimerProbeArguments -Hpet off -Image 'C:\owned\image.qcow2' -FirmwareCode 'C:\owned\code.fd' -FirmwareVariables 'C:\owned\vars.fd' -SerialLog 'C:\owned\serial.log')
$differences=@(for($i=0;$i -lt $default.Count;$i++){if($default[$i] -cne $off[$i]){$i}})
if($default.Count -ne $off.Count -or $differences.Count -ne 1 -or $default[$differences[0]] -cne 'q35' -or $off[$differences[0]] -cne 'q35,hpet=off' -or $default[$differences[0]-1] -cne '-machine'){throw 'timer-control-changes-other-inputs'}
foreach($pair in @(@('-smp','6'),@('-m','4096'),@('-accel','tcg,thread=multi'))){$index=[Array]::IndexOf($off,$pair[0]);if($index -lt 0 -or $off[$index+1] -cne $pair[1]){throw 'timer-control-resources-changed'}}
if(($off -join ' ') -match 'noapic|no_timer_check|icount|-append|-netdev|-nic|-virtfs|-fsdev' -or $off -cnotcontains '-nodefaults' -or $off -cnotcontains '-snapshot'){throw 'timer-control-check-bypass-or-host-exposure'}
$invalid=$false;try{Get-TimerProbeArguments -Hpet bypass}catch{$invalid=$true};if(-not $invalid){throw 'unknown-timer-mode-accepted'}
Write-Host 'PASS timer arguments: only HPET device differs; six CPUs, APIC and guest checks retained; no host/network exposure'
$cpu='[    0.020000] smp: Brought up 1 node, 6 CPUs'
$init='[    1.000000] Run /init as init process'
$panic="[    0.018000] Kernel panic - not syncing: IO-APIC + timer doesn't work!"
foreach($item in @(
    @{text=($cpu+"`n"+$init);ready=$true;panic=$false;io=$false},
    @{text=('[ 0.02] SMP: Total of 6 processors activated (123.00 BogoMIPS).'+"`n[ 1.0] Run /sbin/init as init process");ready=$true;panic=$false;io=$false},
    @{text=($cpu+"`n"+$init+"`n"+$panic);ready=$false;panic=$true;io=$true},
    @{text='[ 0.1] Kernel panic - not syncing: another real panic';ready=$false;panic=$true;io=$false},
    @{text=($cpu.Replace('6 CPUs','4 CPUs')+"`n"+$init);ready=$false;panic=$false;io=$false},
    @{text=($cpu+"`nuser: Run /init as init process");ready=$false;panic=$false;io=$false},
    @{text=('user: '+$cpu+"`n"+$init);ready=$false;panic=$false;io=$false},
    @{text='';ready=$false;panic=$false;io=$false}
)){
    $result=Get-TimerProbeSignals -Text $item.text
    if($result.earlyBootObserved -ne $item.ready -or $result.kernelPanic -ne $item.panic -or $result.ioApicTimerPanic -ne $item.io){throw 'timer-signal-negative-control-failed'}
}
Write-Host 'PASS timer signals: framed early boot, exact six-CPU observation, panic dominance and incomplete/spoof controls'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-TimerProbe.ps1'),[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'timer-probe-syntax'}
$guards=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.IfStatementAst] -and $node.Clauses[0].Item1.Extent.Text -match '\$preflight\.exitCode'},$true))
if($guards.Count -ne 1){throw 'timer-preflight-guard-not-identified'}
foreach($bad in @('none','missing-marker','duplicate-marker','timedOut','cancelled','outputFailed','outputOverflow','forced','activeProcesses','exitCode','childExited')){
    $preflight=@{exitCode=0;childExited=$true;activeProcesses=0;forced=$false;timedOut=$false;cancelled=$false;outputOverflow=$false;outputFailed=$false;records=@(@{Text='RUNLOC_EXACT_ACL_PREFLIGHT=PASS'})}
    switch($bad){
        'missing-marker' {$preflight.records=@()}
        'duplicate-marker' {$preflight.records+=@{Text='RUNLOC_EXACT_ACL_PREFLIGHT=PASS'}}
        'childExited' {$preflight.childExited=$false}
        'activeProcesses' {$preflight.activeProcesses=1}
        'exitCode' {$preflight.exitCode=7}
        'none' {}
        default {$preflight[$bad]=$true}
    }
    $rejected=$false;try{& ([scriptblock]::Create($guards[0].Extent.Text))}catch{$rejected=$_.Exception.Message -ceq 'timer-probe-preflight-failed'}
    if($rejected -ne ($bad -cne 'none')){throw ('timer-preflight-accepted-'+$bad)}
}
Write-Host 'PASS timer preflight: exact single PASS plus exit/process/deadline/output controls required'

# A persistent writer represents QEMU's live serial handle. The reader must see
# newly flushed bytes on each call and refuse oversized data.
$serial=Join-Path ([IO.Path]::GetTempPath()) ('runloc-timer-serial-'+[Guid]::NewGuid().ToString('N'))
$writer=[IO.File]::Open($serial,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::ReadWrite)
try{
    $bytes=[Text.Encoding]::UTF8.GetBytes($cpu+"`n")
    $writer.Write($bytes,0,$bytes.Length);$writer.Flush()
    if((Get-TimerProbeSignals (Read-TimerProbeSerial $serial)).earlyBootObserved){throw 'stale-or-incomplete-serial-accepted'}
    $bytes=[Text.Encoding]::UTF8.GetBytes($init+"`n")
    $writer.Write($bytes,0,$bytes.Length);$writer.Flush()
    if(-not (Get-TimerProbeSignals (Read-TimerProbeSerial $serial)).earlyBootObserved){throw 'live-writer-progress-unreadable'}
    $writer.SetLength(2097153);$writer.Flush();$refused=$false
    try{Read-TimerProbeSerial $serial|Out-Null}catch{$refused=$_.Exception.Message -ceq 'timer-probe-serial-limit'}
    if(-not $refused){throw 'oversize-serial-accepted'}
}finally{$writer.Dispose();[IO.File]::Delete($serial)}
Write-Host 'PASS timer serial: persistent writer readable, fresh bytes observed, bounded overflow refusal'
foreach($script in @('TimerProbe.Workload.ps1','Invoke-TimerProbe.ps1')){
    $null=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $script),[ref]$tokens,[ref]$errors)
    if($errors.Count){throw ('timer-probe-syntax-'+$script)}
}

$hostedGuards=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.IfStatementAst] -and $node.Clauses[0].Item1.Extent.Text -ceq '$HostedDiagnostic'},$true))
if($hostedGuards.Count -ne 1){throw 'hosted-diagnostic-guard-not-identified'}
$names=@('GITHUB_ACTIONS','RUNNER_ENVIRONMENT','GITHUB_REPOSITORY','GITHUB_RUN_ID','GITHUB_EVENT_NAME','GITHUB_ACTOR','GITHUB_RUN_ATTEMPT');$saved=@{}
foreach($name in $names){$saved[$name]=[Environment]::GetEnvironmentVariable($name,'Process')}
try{
    foreach($bad in @('none')+$names){
        $env:GITHUB_ACTIONS='true';$env:RUNNER_ENVIRONMENT='github-hosted';$env:GITHUB_REPOSITORY='techrote/ezvm';$env:GITHUB_RUN_ID='123';$env:GITHUB_EVENT_NAME='workflow_dispatch';$env:GITHUB_ACTOR='techrote';$env:GITHUB_RUN_ATTEMPT='1'
        if($bad -cne 'none'){[Environment]::SetEnvironmentVariable($bad,'wrong','Process')}
        $HostedDiagnostic=$true;$rejected=$false
        try{& ([scriptblock]::Create($hostedGuards[0].Extent.Text))}catch{$rejected=$_.Exception.Message -ceq 'hosted-timer-diagnostic-environment-required'}
        if($rejected -ne ($bad -cne 'none')){throw 'hosted-environment-control-failed'}
    }
}finally{foreach($name in $names){[Environment]::SetEnvironmentVariable($name,$saved[$name],'Process')}}
Write-Host 'PASS hosted diagnostic: explicit opt-in and complete hosted environment required; no qualification path'
