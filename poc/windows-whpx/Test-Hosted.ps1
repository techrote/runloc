#requires -Version 5.1
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
. (Join-Path $PSScriptRoot 'Hosted.Common.ps1')
$child=@{exitCode=0;childExited=$true;activeProcesses=0;forced=$false;outputOverflow=$false;outputFailed=$false}
$events=@($script:PilotMarkers|Where-Object {$_ -cne 'EZVM010_WHPX_EXECUTION'}|ForEach-Object {@{kind='marker';name=$_;value='PASS'}})
1..8|ForEach-Object {$events+=@{kind='phase';name='guest_ready'};$events+=@{kind='guest-cpus';value='6'}}
$events+=@{kind='accelerator';value='tcg'};$events+=@{kind='capability';name='whpx';value='SKIP'}
$telemetry=@{complete=$true;identities=@('source-image','prepared-base','qemu-system','qemu-img'|ForEach-Object {@{kind=$_;sha256=('a'*64)}})}
if(-not (Test-GateHostedOutcome $child $events $telemetry $true)){throw 'valid-hosted-evidence-rejected'}
$count=1
foreach($field in @('exitCode','activeProcesses','forced','outputOverflow','outputFailed','childExited')){
    $bad=$child.Clone();$bad[$field]=if($field -eq 'childExited'){$false}elseif($field -in @('exitCode','activeProcesses')){1}else{$true}
    if(Test-GateHostedOutcome $bad $events $telemetry $true){throw ('unsafe-hosted-child-accepted-'+$field)};$count++
}
if(Test-GateHostedOutcome $child $events $telemetry $false){throw 'changed-source-accepted'};$count++
foreach($variant in @('missing-marker','duplicate-marker','wrong-cpu','conflicting-accelerator','cleanup-error','missing-ready')){
    $bad=@($events|ForEach-Object {$_.Clone()})
    switch($variant){
        'missing-marker' {$bad=@($bad|Where-Object {$_.kind -cne 'marker' -or $_.name -cne $script:PilotMarkers[0]})}
        'duplicate-marker' {$bad+=@{kind='marker';name=$script:PilotMarkers[0];value='PASS'}}
        'wrong-cpu' {($bad|Where-Object {$_.kind -eq 'guest-cpus'}|Select-Object -First 1).value='8'}
        'conflicting-accelerator' {$bad+=@{kind='accelerator';value='whpx'}}
        'cleanup-error' {$bad+=@{kind='failure';name='harness-failure'}}
        'missing-ready' {$index=0;$bad=@($bad|Where-Object {if($_.kind -eq 'phase' -and $index++ -eq 0){$false}else{$true}})}
    }
    if(Test-GateHostedOutcome $child $bad $telemetry $true){throw ('unsafe-hosted-events-accepted-'+$variant)};$count++
}
Write-Host ('Hosted adapter controls passed: '+$count)
