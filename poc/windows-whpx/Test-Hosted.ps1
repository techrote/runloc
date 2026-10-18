#requires -Version 5.1
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
. (Join-Path $PSScriptRoot 'Hosted.Common.ps1')
$child=@{exitCode=0;childExited=$true;activeProcesses=0;forced=$false;outputOverflow=$false;outputFailed=$false}
# Retained physical evidence is a deterministic parser fixture here, never a new TCG PASS.
$fixtureRoot=Join-Path $PSScriptRoot '../../docs/fast-track/evidence/ci-poc-002-full'
$fixture=Get-ChildItem $fixtureRoot -Recurse -Filter receipt.json|ForEach-Object {Get-Content $_.FullName -Raw|ConvertFrom-Json}|Where-Object {$_.outcome -ceq 'pass'}
$events=@($fixture.events|Where-Object {$_.name -cne 'EZVM010_WHPX_EXECUTION'})
($events|Where-Object {$_.kind -ceq 'accelerator'}).value='tcg'
$capability=[pscustomobject]@{kind='capability';name='whpx';value='SKIP';seconds=($events[1].seconds+0.0001);utc=$events[1].utc}
$events=@(($events+@($capability))|Sort-Object -Property {[double]$_.seconds})
$telemetry=$fixture.telemetry;$identities=$fixture.identities
foreach($guest in $identities.guests){$guest.accelerator='tcg'}
if(-not (Test-GateHostedOutcome -Child $child -Events $events -Telemetry $telemetry -SourceUnchanged $true -Identities $identities)){throw 'valid-hosted-evidence-rejected'}
$count=1
if(Test-HostedProcessResolved -Attempted $true -Result $null){throw 'unknown-startup-authorized-disposal'};$count++
if(-not (Test-HostedProcessResolved -Attempted $false -Result $null)){throw 'no-startup-not-empty'};$count++
if(Test-HostedProcessResolved -Attempted $true -Result @{childExited=$true;activeProcesses=1}){throw 'active-child-authorized-disposal'};$count++
if(-not (Test-HostedProcessResolved -Attempted $true -Result $child)){throw 'verified-empty-rejected'};$count++
foreach($field in @('exitCode','activeProcesses','forced','outputOverflow','outputFailed','childExited')){
    $bad=$child.Clone();$bad[$field]=if($field -eq 'childExited'){$false}elseif($field -in @('exitCode','activeProcesses')){1}else{$true}
    if(Test-GateHostedOutcome -Child $bad -Events $events -Telemetry $telemetry -SourceUnchanged $true -Identities $identities){throw ('unsafe-hosted-child-accepted-'+$field)};$count++
}
if(Test-GateHostedOutcome -Child $child -Events $events -Telemetry $telemetry -SourceUnchanged $false -Identities $identities){throw 'changed-source-accepted'};$count++
foreach($variant in @('missing-marker','duplicate-marker','wrong-cpu','conflicting-accelerator','cleanup-error','missing-ready','missing-boundaries','replayed-instance','proof-after-ready')){
    $bad=($events|ConvertTo-Json -Depth 10)|ConvertFrom-Json
    switch($variant){
        'missing-marker' {$bad=@($bad|Where-Object {$_.kind -cne 'marker' -or $_.name -cne $script:PilotMarkers[0]})}
        'duplicate-marker' {$bad+=@{kind='marker';name=$script:PilotMarkers[0];value='PASS'}}
        'wrong-cpu' {($bad|Where-Object {$_.kind -eq 'guest-cpus'}|Select-Object -First 1).value='8'}
        'conflicting-accelerator' {$bad+=@{kind='accelerator';value='whpx'}}
        'cleanup-error' {$bad+=@{kind='failure';name='harness-failure'}}
        'missing-boundaries' {$bad=@($bad|Where-Object {$_.kind -cne 'boundary'})}
        'replayed-instance' {foreach($event in $bad){if($event.kind -ceq 'guest-cpus'){$event.name='ezvm010-source'};if($event.kind -ceq 'phase' -and $event.name -ceq 'guest_ready'){$event.value='ezvm010-source'}}}
        'proof-after-ready' {($bad|Where-Object {$_.kind -ceq 'guest-cpus'}|Select-Object -First 1).seconds+=100}
        'missing-ready' {$firstReady=$bad|Where-Object {$_.kind -ceq 'phase' -and $_.name -ceq 'guest_ready'}|Select-Object -First 1;$bad=@($bad|Where-Object {-not [object]::ReferenceEquals($_,$firstReady)})}
    }
    if(Test-GateHostedOutcome -Child $child -Events $bad -Telemetry $telemetry -SourceUnchanged $true -Identities $identities){throw ('unsafe-hosted-events-accepted-'+$variant)};$count++
}
foreach($pair in @(@('exitCode','0'),@('childExited','false'),@('activeProcesses',$null))){
    $bad=$child.Clone();$bad[$pair[0]]=$pair[1]
    if(Test-GateHostedOutcome -Child $bad -Events $events -Telemetry $telemetry -SourceUnchanged $true -Identities $identities){throw 'coerced-child-type-accepted'};$count++
}
$identities.guests[0].memoryMiB=4096
if(Test-GateHostedOutcome -Child $child -Events $events -Telemetry $telemetry -SourceUnchanged $true -Identities $identities){throw 'wrong-memory-accepted'};$count++
$identities.guests[0].memoryMiB=8192
$telemetry.identities[0].sha256=('f'*64)
if(Test-GateHostedOutcome -Child $child -Events $events -Telemetry $telemetry -SourceUnchanged $true -Identities $identities){throw 'unbound-tool-image-identity-accepted'};$count++
Write-Host ('Hosted adapter controls passed: '+$count)
