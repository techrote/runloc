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
