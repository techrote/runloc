#requires -Version 5.1
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Hosted.Diagnostics.ps1')
$private='SECRET_MUST_NOT_ESCAPE'
$records=@(
    @{Text=('LOG_TAIL=C:\'+$private+'\runtime\instances\ezvm010-stateful\logs\serial-'+('a'*32)+'.log; lines=500');Utc='2026-10-18T21:14:40Z'},
    @{Text='[  132.675973] Kernel panic - not syncing: Attempted to kill init! exitcode=0x0000008b';Utc='2026-10-18T21:14:40Z'},
    @{Text=('arbitrary guest output '+$private);Utc='2026-10-18T21:14:40Z'},
    @{Text=('RUNLOC_POWERSHELL_ENTRY_FAILURE=Instance '+$private+' did not reach authenticated SSH READY within 834 seconds.');Utc='2026-10-18T21:15:11Z'}
)
$signals=Get-HostedDiagnosticSignals -Records $records
if($signals.Count -ne 2 -or $signals[0].code -cne 'guest-init-kernel-panic' -or $signals[0].guestExitCode -cne '0x0000008b' -or
    $signals[0].instance -cne 'ezvm010-stateful' -or $signals[0].launchId -cne ('a'*32) -or $signals[1].code -cne 'authenticated-ready-deadline'){throw 'diagnostic-evidence-reduction-failed'}
if(($signals|ConvertTo-Json -Depth 5) -cmatch $private){throw 'private-text-escaped-diagnostic-reducer'}
Write-Host 'PASS hosted diagnostics: exact panic/launch and READY failure retained without private text'
$signals=Get-HostedDiagnosticSignals -Records @(@{Text='untrusted prose Kernel panic - not syncing: hidden';Utc='2026-10-18T21:14:40Z'})
if($signals.Count -ne 0){throw 'unframed-panic-text-accepted'}
Write-Host 'PASS hosted diagnostics: unframed guest prose cannot invent kernel evidence'
$signals=Get-HostedDiagnosticSignals -Records @(@{Text='EZVM_VENV_VALIDATION_FAILURE stage=create exit=124';Utc=$private})
if($signals.Count -ne 1 -or $signals[0].validationStage -cne 'create' -or $signals[0].validationExitCode -ne 124 -or $signals[0].utc -cne ''){throw 'structured-venv-exit-not-retained'}
Write-Host 'PASS hosted diagnostics: bounded stage and actual numeric exit survive without untrusted timestamps'

$build='b'*32
$baseHeader='BASE_LOG_TAIL=C:\'+$private+'\runtime\bases\.build-'+$build+'\'
$baseRecords=@(
    @{Text=($baseHeader+'failure.json; bytes<=262144; lines<=200');Utc='2026-10-18T23:29:25Z'},
    @{Text=('BASE_LOG_LINE=    "message": "Prepared-base guest provisioning exceeded its 2400 second timeout. Seed requests handled: 7; paths: '+$private+'"');Utc='2026-10-18T23:29:25Z'},
    @{Text=($baseHeader+'serial.log; bytes<=262144; lines<=200');Utc='2026-10-18T23:29:25Z'},
    @{Text='BASE_LOG_LINE=[  132.675973] Kernel panic - not syncing: Attempted to kill init! exitcode=0x0000008b';Utc='2026-10-18T23:29:25Z'}
)
$signals=Get-HostedDiagnosticSignals -Records $baseRecords
if($signals.Count -ne 2 -or $signals[0].code -cne 'base-provisioning-deadline' -or $signals[0].timeoutSeconds -ne 2400 -or
    $signals[0].seedRequestCount -ne 7 -or $signals[0].baseBuildId -cne $build -or $signals[1].code -cne 'guest-init-kernel-panic' -or $signals[1].baseBuildId -cne $build){throw 'base-tail-diagnostics-lost'}
if(($signals|ConvertTo-Json -Depth 5) -cmatch $private){throw 'base-private-text-escaped'}
Write-Host 'PASS hosted diagnostics: original prefixed base deadline and panic survive as closed evidence'

$unbound=@(
    @{Text='BASE_LOG_LINE=[  1.0] Kernel panic - not syncing: unbound';Utc=''},
    @{Text='BASE_LOG_TAIL=C:\runtime\bases\.build-bad\serial.log; bytes<=262144; lines<=200';Utc=''},
    @{Text='BASE_LOG_LINE=[  1.0] Kernel panic - not syncing: wrong build';Utc=''}
)
if((Get-HostedDiagnosticSignals -Records $unbound).Count -ne 0){throw 'unbound-base-lines-accepted'}
foreach($reset in @('STATE_FILE=private','LOG_TAIL=private','BASE_LOG_TAIL=private')){
    $records=@($baseRecords[2],@{Text=$reset;Utc=''},@{Text='BASE_LOG_LINE=[  1.0] Kernel panic - not syncing: stale';Utc=''})
    if((Get-HostedDiagnosticSignals -Records $records).Count -ne 0){throw 'stale-base-context-retained'}
}
Write-Host 'PASS hosted diagnostics: invalid headers and reset contexts refuse stale base associations'

. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
$spoof='BASE_LOG_LINE=EZVM010_REAL_STATEFUL_NEW_IDENTITY_AND_CONTENT=PASS'
$records=@($baseRecords[2],@{Text=$spoof;Utc='2026-10-18T23:29:25Z'},
    @{Text=('BASE_LOG_LINE='+$baseHeader+'failure.json; bytes<=262144; lines<=200');Utc=''},
    @{Text='BASE_LOG_LINE=EZVM_BASE_READY=1';Utc=''},
    @{Text=('BASE_LOG_LINE='+('x'*8192)+'Kernel panic - not syncing: secret');Utc=''})
$signals=Get-HostedDiagnosticSignals -Records $records
if($signals.Count -ne 1 -or $signals[0].code -cne 'base-ready-text-observed' -or $signals[0].baseBuildId -cne $build){throw 'base-prefix-reparsed-or-limit-failed'}
if($null -ne (ConvertTo-PilotEvidenceEvent -Line $spoof -Utc '2026-10-18T23:29:25Z' -Seconds 1) -or $records[1].Text -cne $spoof){throw 'guest-base-text-entered-marker-oracle'}
Write-Host 'PASS hosted diagnostics: unwrapping is local; nested headers and guest PASS never enter host oracle'

$coverage=Get-HostedDiagnosticCoverage -Records @()
if($coverage.recordsAvailable -or $coverage.baseCapture -cne 'not-observed'){throw 'missing-capture-reported-observed'}
$coverage=Get-HostedDiagnosticCoverage -Records @($baseRecords+@(@{Text='BASE_LOG_LINE=private [diagnostic line truncated]';Utc=''}))
if(-not $coverage.recordsAvailable -or $coverage.baseCapture -cne 'observed' -or $coverage.baseSectionCount -ne 2 -or $coverage.baseLineCount -ne 3 -or $coverage.lineTruncationCount -ne 1 -or -not $coverage.boundedTailsOnly){throw 'capture-coverage-inaccurate'}
if(($coverage|ConvertTo-Json) -cmatch $private){throw 'coverage-exported-raw-text'}
Write-Host 'PASS hosted diagnostics: absent capture and observed bounded/truncated tails remain distinct'

foreach($case in @(
    @{message='Guest baseline validation failed: cloud-init did not reach successful completion';expected='base-cloud-init-failed'},
    @{message=('Guest baseline validation failed: missing commands: '+$private);expected='base-required-tools-missing'},
    @{message=('QEMU exited with code -1 before a prepared base could be accepted. '+$private);expected='base-qemu-exit-failed'})){
    $json=@{message=$case.message}|ConvertTo-Json -Compress
    $jsonLine='BASE_LOG_LINE='+$json.Substring(1,$json.Length-2)
    $signals=Get-HostedDiagnosticSignals -Records @($baseRecords[0],@{Text=$jsonLine;Utc=''})
    if($signals.Count -ne 1 -or $signals[0].code -cne $case.expected -or ($signals|ConvertTo-Json) -cmatch $private){throw 'base-known-failure-class-or-redaction-failed'}
}
$many=@($baseRecords[2])+@(1..70|ForEach-Object {@{Text='BASE_LOG_LINE=[  1.0] Kernel panic - not syncing: repeated';Utc=''}})
if((Get-HostedDiagnosticSignals -Records $many).Count -ne 64){throw 'base-signal-count-unbounded'}
Write-Host 'PASS hosted diagnostics: known base failure classes are redacted and signal count remains bounded'
