#requires -Version 5.1
[CmdletBinding()]param([Parameter(Mandatory=$true)][string]$PlanPath,[Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{64}$')][string]$PlanSha256)
$ErrorActionPreference='Stop';$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
Import-PilotNative
$principal=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -or [RunlocPoc.OwnedProcess]::CurrentTokenHasPrivilege('SeSecurityPrivilege')){throw 'standard-user-without-security-privilege-required'}
$PlanPath=Assert-PilotPath -Path $PlanPath -File
if((Get-PilotDigest -Path $PlanPath) -cne $PlanSha256){throw 'diagnostic-plan-changed'}
$plan=[IO.File]::ReadAllText($PlanPath)|ConvertFrom-Json
if($plan.scenario -cnotin @('basic-clones','release-order','full-forensic')){throw 'diagnostic-scenario-invalid'}
$fullForensic=$plan.scenario -ceq 'full-forensic'
$state=Assert-PilotPath -Path $plan.stateRoot
if([IO.Path]::GetDirectoryName($PlanPath) -cne $state){throw 'diagnostic-state-mismatch'}
$me=Get-CimInstance Win32_Process -Filter ('ProcessId='+$PID)
$parent=Get-CimInstance Win32_Process -Filter ('ProcessId='+$me.ParentProcessId)
if($null -eq $parent -or $parent.Name -cne 'explorer.exe' -or $parent.CreationDate -ge $me.CreationDate){throw 'independent-explorer-parent-required'}
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$controller=Get-PilotSourceIdentity -Root $root -Repository 'https://github.com/techrote/runloc' -ExpectedCommit $plan.controllerCommit
$candidate=Get-PilotSourceIdentity -Root $plan.candidateRoot -Repository 'https://github.com/techrote/ezvm' -ExpectedCommit $plan.candidateCommit
$backing=Assert-PilotPath -Path $plan.backingRoot
$workParent=[Environment]::GetFolderPath('UserProfile')
$drive=New-Object IO.DriveInfo([IO.Path]::GetPathRoot($workParent))
if($drive.AvailableFreeSpace -lt 60GB){throw 'diagnostic-requires-sixty-gib-free'}
$capacity=[IO.File]::Open((Join-Path $backing 'runner-capacity.lock'),[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
$clock=[Diagnostics.Stopwatch]::StartNew();$lease=$null;$job=$null;$complete=$false;$empty=$false;$removed=$false;$code=$null;$forced=$false
$preflight=$null;$telemetry=$null;$diagnosticEvents=New-Object 'System.Collections.Generic.List[object]'
function Write-GuestDiagnosticRecord {
    param([object]$Record)
    if($Record.Text -cmatch '^DIAGNOSTIC_(PHASE|ONLY|STOP_UNCONFIRMED)='){Write-Host ($Record.Utc+' '+$Record.Text)}
    elseif($fullForensic){
        $event=ConvertTo-PilotEvidenceEvent -Line $Record.Text -Utc $Record.Utc -Seconds ([double]$Record.Seconds)
        if($null -ne $event){
            if($diagnosticEvents.Count -ge 10000){throw 'diagnostic-event-bound-exceeded'}
            $diagnosticEvents.Add($event)
            Write-Host ($Record.Utc+' WORKLOAD_EVENT '+($event|ConvertTo-Json -Compress))
        }
    }
}
try{
    $lease=New-PilotLease -EvidenceParent $state -CandidateCommit $plan.candidateCommit -ControllerCommit $plan.controllerCommit -WorkParent $workParent
    Assert-PilotFixtureSeparation -Fixture $lease.Fixture -ProtectedRoots @($root,$plan.candidateRoot,$backing)
    New-PilotFixture -Lease $lease
    $exe=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    if($fullForensic){
        $aclArguments=Get-PilotPowerShellArguments -TargetScript (Join-Path $PSScriptRoot 'Invoke-AclPreflight.ps1') -NamedParameters @{SourceRoot=$plan.candidateRoot;ProbeDirectory=(Join-Path $lease.Private 'acl-probe')}
        $preflight=Invoke-PilotChild -Executable $exe -Arguments $aclArguments -WorkingDirectory $plan.candidateRoot -TemporaryDirectory $lease.Fixture -RawLogPath (Join-Path $lease.Private 'preflight.log') -Clock $clock -ExecutionDeadlineSeconds ($clock.Elapsed.TotalSeconds+60) -CleanupDeadlineSeconds ($clock.Elapsed.TotalSeconds+70)
        if($preflight.exitCode -ne 0 -or -not $preflight.childExited -or $preflight.activeProcesses -ne 0 -or $preflight.forced -or $preflight.timedOut -or $preflight.cancelled -or $preflight.outputFailed -or $preflight.outputOverflow -or @($preflight.records|Where-Object {$_.Text -ceq 'RUNLOC_EXACT_ACL_PREFLIGHT=PASS'}).Count -ne 1){throw 'exact-acl-preflight-failed'}
        Write-Host 'DIAGNOSTIC_PHASE=exact-acl-preflight-passed'
    }
    $parameters=@{SourceRoot=$plan.candidateRoot;Fixture=$lease.Fixture;PrivateEvidence=$lease.Private;Scenario=$plan.scenario}
    $arguments=Get-PilotPowerShellArguments -TargetScript (Join-Path $PSScriptRoot 'GuestDiagnostic.Workload.ps1') -NamedParameters $parameters
    Write-Host 'Explorer-owned DIAGNOSTIC ONLY. Six-vCPU WHPX; no GitHub runner or full qualification.'
    if($fullForensic){Write-Host 'Full original workload; NoOverallTimeout diagnostic policy. Failed fixtures stay private. This is not Actions acceptance.'}
    Write-Host ('Private lease: '+$lease.Root)
    $job=New-Object RunlocPoc.OwnedProcess($exe,$arguments,$root,$lease.Fixture,(Join-Path $lease.Private 'diagnostic.log'),[long]16777216)
    $lastHeartbeat=0
    while(-not $job.HasExited){
        foreach($record in $job.Drain()){Write-GuestDiagnosticRecord -Record $record}
        if($job.OutputFailed -or $job.OutputOverflow){throw 'diagnostic-output-incomplete'}
        if(-not $fullForensic -and $clock.Elapsed.TotalSeconds -gt 3600){throw 'diagnostic-one-hour-wall'}
        if($clock.Elapsed.TotalSeconds-$lastHeartbeat -ge 15){Write-Host ([DateTime]::UtcNow.ToString('o')+' DIAGNOSTIC_HEARTBEAT elapsed='+[Math]::Round($clock.Elapsed.TotalSeconds)+' ownedProcesses='+$job.ActiveProcesses);$lastHeartbeat=$clock.Elapsed.TotalSeconds}
        Start-Sleep -Milliseconds 100
    }
    $code=$job.ExitCode;$complete=$code -eq 0
}finally{
    $errors=@();$sourceUnchanged=$false;$candidateAfter=$null;$controllerAfter=$null
    try{
        if($null -ne $job){
            try{
                if(-not $job.HasExited -or $job.ActiveProcesses -gt 0){$forced=$true;$complete=$false;$job.Terminate()}
                $wait=[Diagnostics.Stopwatch]::StartNew()
                while((-not $job.HasExited -or $job.ActiveProcesses -gt 0) -and $wait.Elapsed.TotalSeconds -lt 30){Start-Sleep -Milliseconds 100}
                $empty=$job.HasExited -and $job.ActiveProcesses -eq 0
                if($job.HasExited){$code=$job.ExitCode}
                $drained=$job.FinishOutput(3000)
                foreach($record in $job.Drain()){Write-GuestDiagnosticRecord -Record $record}
                if(-not $drained -or $job.OutputFailed -or $job.OutputOverflow){$complete=$false}
            }catch{$complete=$false;$empty=$false;$errors+='process-cleanup-unconfirmed'}
            finally{try{$job.Dispose()}catch{$complete=$false;$empty=$false;$errors+='job-disposal-unconfirmed'}}
        }
        if($fullForensic -and $null -ne $lease){
            try{
                $telemetry=Read-PilotTelemetry -Path (Join-Path $lease.Private 'full-telemetry.jsonl') -OutputPath (Join-Path $state 'telemetry-events.json') -Clock $clock -DeadlineSeconds ([double]::PositiveInfinity) -NoOverallTimeout
                if(-not $telemetry.complete){$complete=$false}
                foreach($marker in $script:PilotMarkers){
                    if(@($diagnosticEvents|Where-Object {$_.kind -ceq 'marker' -and $_.name -ceq $marker -and $_.value -ceq 'PASS'}).Count -ne 1){$complete=$false}
                }
            }catch{$complete=$false;$errors+='full-diagnostic-evidence-unconfirmed'}
        }
        try{
            $candidateAfter=Get-PilotSourceIdentity -Root $plan.candidateRoot -Repository 'https://github.com/techrote/ezvm' -ExpectedCommit $plan.candidateCommit -ExpectedTree $candidate.tree
            $controllerAfter=Get-PilotSourceIdentity -Root $root -Repository 'https://github.com/techrote/runloc' -ExpectedCommit $plan.controllerCommit -ExpectedTree $controller.tree
            $sourceUnchanged=$candidateAfter.executedTreeSha256 -ceq $candidate.executedTreeSha256 -and $controllerAfter.executedTreeSha256 -ceq $controller.executedTreeSha256
            if(-not $sourceUnchanged){$complete=$false}
        }catch{$complete=$false;$errors+='source-after-unconfirmed'}
        if($null -ne $lease){
            try{
                if($complete -and $empty){Remove-PilotFixture -Lease $lease -Clock $clock -DeadlineSeconds ($clock.Elapsed.TotalSeconds+180) -OwnedProcessesExited $true;$removed=$true}
            }catch{$complete=$false;$errors+='fixture-disposal-unconfirmed'}
            # Failed fixtures are private forensic quarantine, never reusable
            # bases or successful full-qualification disposal evidence.
            try{
                Write-PilotNewJson -Path (Join-Path $state 'diagnostic-result.json') -Value @{schemaVersion=1;diagnosticOnly=$true;qualificationPassed=$false;scenario=$plan.scenario;
                    diagnosticCompleted=$complete;childExitCode=$code;forced=$forced;activeOwnedProcesses=$(if($empty){0}else{$null});fixtureRemoved=$removed;
                    forensicQuarantineRequired=(-not $removed);leaseId=$lease.Id;candidate=$candidate;controller=$controller;candidateAfter=$candidateAfter;
                    controllerAfter=$controllerAfter;sourceUnchanged=$sourceUnchanged;errors=$errors;elapsedSeconds=$clock.Elapsed.TotalSeconds;
                    noOverallTimeout=$fullForensic;preflightExitCode=$(if($null -ne $preflight){$preflight.exitCode}else{$null});events=$diagnosticEvents.ToArray();telemetry=$telemetry;
                    preflightTimedOut=$(if($null -ne $preflight){$preflight.timedOut}else{$null});preflightCancelled=$(if($null -ne $preflight){$preflight.cancelled}else{$null});
                    actionsAssociation='none-diagnostic-only'}
            }catch{$complete=$false;Write-Host 'DIAGNOSTIC_RECEIPT_WRITE_FAILED=quarantine-no-qualification'}
        }
    }finally{
        try{if($null -ne $lease){$lease.Lock.Dispose()}}finally{$capacity.Dispose()}
    }
}
Write-Host 'Diagnostic stopped. Its receipt never qualifies the complete release scenario.'
