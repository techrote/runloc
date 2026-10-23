#requires -Version 5.1
$ErrorActionPreference='Stop'
$sandbox=Join-Path ([IO.Path]::GetTempPath()) ('runloc-full-diagnostic-test-'+[Guid]::NewGuid().ToString('N'))
$scripts=Join-Path $sandbox 'scripts'
[void][IO.Directory]::CreateDirectory($scripts)
$harness=Join-Path $scripts 'Invoke-EzVm010RealPortability.ps1'
$private=Join-Path $sandbox 'private evidence'
$fixture=Join-Path $sandbox 'fixture must not be created by wrapper'
try{
    [IO.File]::WriteAllText($harness,@'
param([string]$Root,[switch]$ReleaseQualification,[string]$Accelerator,[int]$QualificationCpus,[string]$TelemetryPath)
@{root=$Root;release=[bool]$ReleaseQualification;accelerator=$Accelerator;cpus=$QualificationCpus;telemetry=$TelemetryPath}|ConvertTo-Json -Compress
'@)
    $output=@(& (Join-Path $PSScriptRoot 'GuestDiagnostic.Workload.ps1') -SourceRoot $sandbox -Fixture $fixture -PrivateEvidence $private -Scenario full-forensic)
    $call=$output[-1]|ConvertFrom-Json
    if($call.root -cne $sandbox -or -not $call.release -or $call.accelerator -cne 'whpx' -or $call.cpus -ne 6 -or
        $call.telemetry -cne (Join-Path $private 'full-telemetry.jsonl') -or [IO.Directory]::Exists($fixture)){throw 'full-workload-routing-changed'}
    Write-Host 'PASS full diagnostic: original full entry receives exact resources/telemetry without reduced clone workload'
    [IO.File]::WriteAllText($harness,"throw 'synthetic-full-workload-failure'")
    $refused=$false
    try{& (Join-Path $PSScriptRoot 'GuestDiagnostic.Workload.ps1') -SourceRoot $sandbox -Fixture $fixture -PrivateEvidence $private -Scenario full-forensic}catch{$refused=$_.Exception.Message -ceq 'synthetic-full-workload-failure'}
    if(-not $refused){throw 'full-workload-failure-hidden'}
    Write-Host 'PASS full diagnostic: original workload failure propagates'
    [IO.File]::WriteAllText($harness,'exit 7')
    $refused=$false
    try{& (Join-Path $PSScriptRoot 'GuestDiagnostic.Workload.ps1') -SourceRoot $sandbox -Fixture $fixture -PrivateEvidence $private -Scenario full-forensic}catch{$refused=$_.Exception.Message -ceq 'diagnostic-full-workload-failed'}
    if(-not $refused){throw 'nonzero-full-script-exit-hidden'}
    Write-Host 'PASS full diagnostic: explicit nonzero script exit cannot become successful execution'

    $tokens=$null;$errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-GuestDiagnostic.ps1'),[ref]$tokens,[ref]$errors)
    if($errors.Count -ne 0){throw 'diagnostic-controller-syntax'}
    $wall=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.IfStatementAst] -and $node.Clauses[0].Item1.Extent.Text -ceq '-not $fullForensic -and $clock.Elapsed.TotalSeconds -gt 3600'},$true))
    if($wall.Count -ne 1){throw 'diagnostic-wall-not-identified'}
    $clock=@{Elapsed=@{TotalSeconds=3601}}
    $fullForensic=$true
    & ([scriptblock]::Create($wall[0].Extent.Text))
    $fullForensic=$false;$bounded=$false
    try{& ([scriptblock]::Create($wall[0].Extent.Text))}catch{$bounded=$_.Exception.Message -ceq 'diagnostic-one-hour-wall'}
    if(-not $bounded){throw 'focused-diagnostic-wall-disabled'}
    Write-Host 'PASS full diagnostic: full-only no-overall policy leaves focused one-hour containment intact'
    foreach($name in @('Invoke-GuestDiagnostic.ps1','Invoke-HostedQualification.ps1','Pilot.Controller.ps1')){
        $guardAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $name),[ref]$tokens,[ref]$errors)
        $guards=@($guardAst.FindAll({param($node) $node -is [Management.Automation.Language.IfStatementAst] -and
            $node.Clauses[0].Item1.Extent.Text -match '\$preflight\.exitCode' -and $node.Extent.Text -match "throw 'exact-acl-preflight-failed'"},$true))
        if($guards.Count -ne 1){throw 'preflight-guard-not-identified'}
        foreach($bad in @('none','timedOut','cancelled')){
            $preflight=@{exitCode=0;childExited=$true;activeProcesses=0;forced=$false;timedOut=$false;cancelled=$false;outputFailed=$false;outputOverflow=$false;records=@(@{Text='RUNLOC_EXACT_ACL_PREFLIGHT=PASS'})}
            if($bad -cne 'none'){$preflight[$bad]=$true}
            $rejected=$false
            try{& ([scriptblock]::Create($guards[0].Extent.Text))}catch{$rejected=$_.Exception.Message -ceq 'exact-acl-preflight-failed'}
            if($rejected -ne ($bad -cne 'none')){throw 'preflight-deadline-or-cancel-race-accepted'}
        }
    }
    Write-Host 'PASS full diagnostic: timed-out/cancelled preflight cannot pass through a racing zero exit in any controller'
}finally{
    # Remove only the exact files/directories this synthetic test created.
    if([IO.File]::Exists($harness)){[IO.File]::Delete($harness)}
    if([IO.Directory]::Exists($scripts)){[IO.Directory]::Delete($scripts,$false)}
    if([IO.Directory]::Exists($sandbox)){[IO.Directory]::Delete($sandbox,$false)}
}
