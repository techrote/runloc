#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidatePattern('^[a-f0-9]{40}$')][string]$ExpectedControllerCommit,
    [Parameter(Mandatory = $true)][ValidatePattern('^[a-f0-9]{32}$')][string]$ComparisonId,
    [Parameter(Mandatory = $true)][ValidateSet('qualification', 'probe')][string]$Mode
)
$ErrorActionPreference = 'Stop'
$env:PSModulePath = [IO.Path]::Combine($PSHOME, 'Modules')
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
if ($env:GITHUB_REPOSITORY -cne 'techrote/ezvm' -or $env:GITHUB_EVENT_NAME -cne 'workflow_dispatch' -or
    $env:RUNNER_NAME -cne ('runloc-' + $ComparisonId) -or $env:GITHUB_RUN_ID -cnotmatch '^[1-9][0-9]*$' -or
    $env:GITHUB_RUN_ATTEMPT -cne '1') { throw 'trusted-one-job-context-required' }
$controllerRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$controller = Get-PilotSourceIdentity -Root $controllerRoot -Repository 'https://github.com/techrote/runloc' -ExpectedCommit $ExpectedControllerCommit
$pin = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'candidate.json')) | ConvertFrom-Json
# Keep ownership/evidence outside _temp: the runner cleans that directory at
# job completion, before the host supervisor audits nested external fixtures.
$parent = Assert-PilotPath -Path ([IO.Path]::GetDirectoryName($env:RUNNER_TEMP))
if ([IO.Path]::GetFileName($parent) -cne '_work') { throw 'runner-work-root-invalid' }
$root = Join-Path $parent ('j' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
Import-PilotNative
[RunlocPoc.OwnedProcess]::CreateNewDirectory($root)
Set-PilotPrivateDirectory -Path $root
$candidateRoot = Join-Path $root 'EzVM'
$evidence = Join-Path $root 'Evidence'
$public = Join-Path $root 'Public'
[void][IO.Directory]::CreateDirectory($evidence)
[void][IO.Directory]::CreateDirectory($public)
git clone --no-checkout https://github.com/techrote/ezvm $candidateRoot
if ($LASTEXITCODE -ne 0) { throw 'candidate-clone-failed' }
git -C $candidateRoot config core.autocrlf false
if ($LASTEXITCODE -ne 0) { throw 'candidate-configuration-failed' }
git -C $candidateRoot config core.eol lf
if ($LASTEXITCODE -ne 0) { throw 'candidate-configuration-failed' }
git -C $candidateRoot checkout --detach $pin.commit
if ($LASTEXITCODE -ne 0) { throw 'candidate-checkout-failed' }
$candidate = Get-PilotSourceIdentity -Root $candidateRoot -Repository $pin.repository -ExpectedCommit $pin.commit -ExpectedTree $pin.tree -Pins $pin.pins
$clock = [Diagnostics.Stopwatch]::StartNew()
$powershell = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
$entry = Join-Path $PSScriptRoot 'Invoke-WhpxPilot.ps1'
$exitCodes = @(); $terminalLines = @()
$phases = @('preflight')
if ($Mode -ceq 'qualification') { $phases += 'qualification' }
foreach ($phase in $phases) {
    $arguments = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $entry,
        '-CandidateRoot', $candidateRoot, '-ExpectedControllerCommit', $ExpectedControllerCommit,
        '-EvidenceParent', $evidence, '-WorkParent', [Environment]::GetFolderPath('UserProfile'), '-HostLabel', 'lab-win11-01', '-NoOverallTimeout')
    if ($phase -ceq 'preflight') { $arguments += '-PreflightOnly' }
    # Invoke-PilotChild creates a dedicated File process and a nested owned Job.
    # No overall timer/target is added around the owner's completion policy.
    $child = Invoke-PilotChild -Executable $powershell -Arguments $arguments -WorkingDirectory $controllerRoot -TemporaryDirectory $root `
        -RawLogPath (Join-Path $root ($phase + '.log')) -Clock $clock -ExecutionDeadlineSeconds ([double]::PositiveInfinity) -CleanupDeadlineSeconds ([double]::PositiveInfinity)
    $terminal = @($child.records | Where-Object { $_.Text -cmatch '^RUNLOC_WHPX_SUPERVISOR_OUTCOME=' })
    $expected = if ($phase -ceq 'preflight') { 'preflight-pass' } else { 'pass' }
    $phasePassed = $child.exitCode -eq 0 -and $child.childExited -and $child.activeProcesses -eq 0 -and -not $child.forced -and
        -not $child.outputFailed -and -not $child.outputOverflow -and $terminal.Count -eq 1 -and
        $terminal[0].Text -cmatch ('^RUNLOC_WHPX_SUPERVISOR_OUTCOME=' + $expected + '; elapsedSeconds=[0-9.]+$')
    $exitCodes += @{ phase = $phase; exitCode = $child.exitCode; passed = $phasePassed; activeProcesses = $child.activeProcesses;
        terminal = $(if ($terminal.Count -eq 1) { $terminal[0].Text } else { '' }); endedSeconds = $clock.Elapsed.TotalSeconds }
    if (-not $phasePassed) { break }
}
# Copy only the named allowlisted files. The enclosing attempts contain private
# logs, leases and guest keys and must never be uploaded as a directory glob.
foreach ($outer in @(Get-ChildItem -LiteralPath $evidence -Directory)) {
    $outerPublic = Join-Path $public $outer.Name
    [void][IO.Directory]::CreateDirectory($outerPublic)
    foreach ($name in @('supervisor-started.json', 'supervisor-receipt.json', 'supervisor-receipt-digest.json')) {
        $path = Join-Path $outer.FullName $name
        if ([IO.File]::Exists($path)) { $null = Assert-PilotPath -Path $path -File; [IO.File]::Copy($path, (Join-Path $outerPublic $name), $false) }
    }
    $attempts = Join-Path $outer.FullName 'private/attempts'
    if ([IO.Directory]::Exists($attempts)) {
        foreach ($inner in @(Get-ChildItem -LiteralPath $attempts -Directory)) {
            $innerPublic = Join-Path $outerPublic $inner.Name
            [void][IO.Directory]::CreateDirectory($innerPublic)
            foreach ($name in @('receipt.json', 'receipt-digest.json', 'telemetry-events.json')) {
                $path = Join-Path $inner.FullName $name
                if ([IO.File]::Exists($path)) { $null = Assert-PilotPath -Path $path -File; [IO.File]::Copy($path, (Join-Path $innerPublic $name), $false) }
            }
        }
    }
}
$passed = $exitCodes.Count -eq $phases.Count -and @($exitCodes | Where-Object { -not $_.passed }).Count -eq 0
Write-PilotNewJson -Path (Join-Path $public 'actions-job.json') -Value @{
    schemaVersion = 1; issue = 'CI-POC-002'; repository = 'techrote/ezvm'; comparisonId = $ComparisonId;
    runId = [long]$env:GITHUB_RUN_ID; runAttempt = [int]$env:GITHUB_RUN_ATTEMPT; runnerName = $env:RUNNER_NAME; workflowSha = $env:GITHUB_SHA;
    controller = $controller; candidate = $candidate; mode = $Mode; overallTimeoutDisabled = $true; qualificationCpus = 6;
    physicalQualificationPassed = ($passed -and $Mode -ceq 'qualification'); passed = $passed; phases = $exitCodes; elapsedSeconds = $clock.Elapsed.TotalSeconds }
('public_evidence=' + $public) | Out-File -LiteralPath $env:GITHUB_OUTPUT -Append -Encoding utf8
if (-not $passed) { exit 1 }
exit 0
