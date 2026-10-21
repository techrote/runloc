#requires -Version 5.1
[CmdletBinding()]param([string]$SourceRoot,[string]$Fixture,[string]$PrivateEvidence)
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
. (Join-Path $PSScriptRoot 'TimerProbe.Common.ps1')
Import-PilotNative
$clock=[Diagnostics.Stopwatch]::StartNew();$cases=@();$resolved=$true;$failure='';$failureDetail='';$identities=@{}
try{
    $root=Join-Path $Fixture 'timer-diagnostic'
    [void][IO.Directory]::CreateDirectory($root)
    foreach($relative in @('ezvm.ps1','src','config','manifests','guest','scripts','tools')){Copy-Item -LiteralPath (Join-Path $SourceRoot $relative) -Destination $root -Recurse}
    Import-Module (Join-Path $root 'src/EzVm/EzVm.psd1') -Force
    $null=Install-EzVmQemuRuntime -Root $root
    $null=Invoke-EzVmSourceImageAcquire -Root $root
    $image=Get-EzVmVerifiedSourceImage -Root $root
    $status=Get-EzVmManagedQemuStatus -Root $root
    if(-not $status.Valid){throw 'timer-probe-qemu-not-verified'}
    $identities=@{qemuSha256=(Get-PilotDigest $status.QemuSystem);imageSha256=(Get-PilotDigest $image.path);requestedCpus=6;memoryMiB=4096;accelerator='tcg';network='none';disk='fresh-temporary-snapshot-each-boot'}
    foreach($number in 1..3){foreach($mode in @('default','off')){
        $id=('boot-'+$number+'-'+$mode);$stage=Join-Path $Fixture $id;[void][IO.Directory]::CreateDirectory($stage)
        $firmware=& (Get-Module EzVm) {param($r,$s) Get-EzVmBaseFirmwarePaths -Root $r -StagingDirectory $s} $root $stage
        $serial=Join-Path $stage 'serial.log';$job=$null;$signals=Get-TimerProbeSignals -Text '';$stop='';$started=$clock.Elapsed.TotalSeconds
        $case=@{name=$id;hpet=$mode;requestedCpus=6;plannedDiagnosticTermination=$true;terminationIssued=$false;qualificationPassed=$false}
        try{
            $arguments=Get-TimerProbeArguments -Hpet $mode -Image $image.path -FirmwareCode $firmware.Code -FirmwareVariables $firmware.Variables -SerialLog $serial
            $case.arguments=$arguments
            $case.firmwareCodeSha256=Get-PilotDigest $firmware.Code
            $case.firmwareVariablesInitialSha256=Get-PilotDigest $firmware.Variables
            $job=New-Object RunlocPoc.OwnedProcess($status.QemuSystem,$arguments,$stage,$stage,(Join-Path $PrivateEvidence ($id+'-process.log')),1048576)
            Write-Host ('TIMER_PROBE_START='+$id)
            while(-not $job.HasExited){
                [void]$job.Drain()
                if([IO.File]::Exists($serial)){
                    if((Get-Item -LiteralPath $serial).Length -gt 2097152){$stop='serial-limit';break}
                    $signals=Get-TimerProbeSignals -Text (Read-TimerProbeSerial -Path $serial)
                    if($signals.kernelPanic){$stop='kernel-panic';break}
                    if($signals.earlyBootObserved){$stop='kernel-init-and-six-cpu-observed';break}
                }
                if($clock.Elapsed.TotalSeconds-$started -ge 180){$stop='diagnostic-deadline';break}
                if($job.OutputOverflow -or $job.OutputFailed){$stop='process-output-failure';break}
                Start-Sleep -Milliseconds 100
            }
        }finally{
            if($null -ne $job){
                try{
                    if(-not $job.HasExited -or $job.ActiveProcesses -gt 0){$case.terminationIssued=$true;$job.Terminate()}
                    $cleanupDeadline=$clock.Elapsed.TotalSeconds+30
                    while((-not $job.HasExited -or $job.ActiveProcesses -gt 0) -and $clock.Elapsed.TotalSeconds -lt $cleanupDeadline){Start-Sleep -Milliseconds 50}
                    $case.childExited=$job.HasExited;$case.activeProcesses=$job.ActiveProcesses
                    $case.actualExitCode=$(if($job.HasExited){$job.ExitCode}else{$null})
                    $case.outputComplete=$job.FinishOutput(3000);[void]$job.Drain()
                    $case.outputOverflow=$job.OutputOverflow;$case.outputFailed=$job.OutputFailed
                    $resolved=$resolved -and $job.HasExited -and $job.ActiveProcesses -eq 0
                }finally{$job.Dispose()}
            }else{$resolved=$false}
        }
        if([IO.File]::Exists($serial)){
            $raw=[IO.File]::ReadAllBytes($serial);if($raw.Length -gt 2097152){throw 'timer-probe-serial-limit'}
            [IO.File]::WriteAllBytes((Join-Path $PrivateEvidence ($id+'-serial.private.log')),$raw)
            $case.serialSha256=Get-PilotDigest $serial
        }
        if($case.outputOverflow -or $case.outputFailed -or -not $case.outputComplete){$failure='diagnostic-output-failed'}
        $signals=Get-TimerProbeSignals -Text (Read-TimerProbeSerial -Path $serial)
        $case.classification=$(if($signals.kernelPanic){'kernel-panic'}elseif($signals.earlyBootObserved){'early-boot-observed-not-qualified'}else{'inconclusive'})
        if(-not $stop){$stop='process-exited-before-observation'}
        $case.signals=$signals;$case.stopReason=$stop;$case.elapsedSeconds=$clock.Elapsed.TotalSeconds-$started
        $cases+=,$case
        Write-Host ('TIMER_PROBE_RESULT='+($case|ConvertTo-Json -Depth 4 -Compress))
        if(-not $resolved){throw 'timer-probe-process-cleanup-unresolved'}
    }}
    if((Get-PilotDigest $image.path) -cne $identities.imageSha256 -or (Get-PilotDigest $status.QemuSystem) -cne $identities.qemuSha256){throw 'timer-probe-input-changed'}
}catch{$failure='diagnostic-incomplete';$failureDetail=$_.Exception.Message+' line='+$_.InvocationInfo.ScriptLineNumber}finally{
    Write-PilotNewJson -Path (Join-Path $PrivateEvidence 'timer-workload.json') -Value @{diagnosticOnly=$true;qualificationPassed=$false;cases=$cases;identities=$identities;processesResolved=$resolved;failure=$failure;failureDetail=$failureDetail}
}
if($failure -or -not $resolved -or $cases.Count -ne 6){exit 1}
exit 0
