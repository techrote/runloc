#requires -Version 5.1
[CmdletBinding()]param([Parameter(Mandatory=$true)][string]$SourceRoot,[Parameter(Mandatory=$true)][string]$Fixture,
    [Parameter(Mandatory=$true)][string]$PrivateEvidence,
    [ValidateSet('basic-clones','release-order')][string]$Scenario='basic-clones')
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
$root=Join-Path $Fixture 'guest diagnostic'
$null=New-Item -ItemType Directory -Path $root
foreach($relative in @('ezvm.ps1','src','config','manifests','guest','scripts','tools')){
    Copy-Item -LiteralPath (Join-Path $SourceRoot $relative) -Destination $root -Recurse
}
Import-Module (Join-Path $root 'src/EzVm/EzVm.psd1') -Force
. (Join-Path $SourceRoot 'scripts/QualificationResources.ps1')
Set-EzVmQualificationResources -Root $root -Cpus 6
$active=New-Object 'System.Collections.Generic.List[string]'
function Save-GuestDiagnosticLogs {
    foreach($name in $active){
        $paths=Get-EzVmInstanceRuntimePaths -Root $root -InstanceName $name
        $destination=Join-Path $PrivateEvidence $name
        [void][IO.Directory]::CreateDirectory($destination)
        if([IO.Directory]::Exists($paths.Logs)){
            foreach($file in Get-ChildItem -LiteralPath $paths.Logs -File){
                if($file.Name -cmatch '^(serial|qemu)-[a-f0-9]{32}\.log$'){
                    Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $destination $file.Name) -Force
                }
            }
        }
    }
}
function Start-DiagnosticGuest {
    param([string]$Name,[switch]$WritePersistence,[switch]$CheckPersistence,[switch]$CheckPristine)
    $active.Add($Name)
    Write-Host ('DIAGNOSTIC_PHASE=guest-start; instance='+$Name)
    $ready=Start-EzVmReadyInstance -Root $root -InstanceName $Name -Accelerator whpx -ReadyTimeoutSeconds 900
    $cpu=Invoke-EzVmExec -Root $root -InstanceName $Name -Command @('getconf','_NPROCESSORS_ONLN') -TimeoutSeconds 60
    if($ready.state -cne 'READY' -or $ready.accelerator -cne 'whpx' -or $cpu.exitCode -ne 0 -or $cpu.stdout.Trim() -cne '6'){throw 'diagnostic-guest-proof-failed'}
    Write-Host ('DIAGNOSTIC_PHASE=authenticated-ready-six-cpu; instance='+$Name)
    if($WritePersistence){
        $result=Invoke-EzVmExec -Root $root -InstanceName $Name -Command @('sh','-c',"set -eu; umask 077; mkdir -p /home/coder/.config/ezvm-diagnostic; printf '%s' diagnostic-only-workspace > /home/coder/workspace/ezvm-diagnostic.txt; printf '%s' synthetic-only > /home/coder/.config/ezvm-diagnostic/state; sync") -TimeoutSeconds 120
        if($result.exitCode -ne 0){throw 'diagnostic-persistence-write-failed'}
    }
    if($CheckPersistence){
        $result=Invoke-EzVmExec -Root $root -InstanceName $Name -Command @('sh','-c','set -eu; test "$(cat /home/coder/workspace/ezvm-diagnostic.txt)" = diagnostic-only-workspace; test "$(cat /home/coder/.config/ezvm-diagnostic/state)" = synthetic-only') -TimeoutSeconds 120
        if($result.exitCode -ne 0){throw 'diagnostic-persistence-check-failed'}
    }
    if($CheckPristine){
        $result=Invoke-EzVmExec -Root $root -InstanceName $Name -Command @('sh','-c','set -eu; test ! -e /home/coder/workspace/ezvm-diagnostic.txt; test ! -e /home/coder/.config/ezvm-diagnostic/state') -TimeoutSeconds 120
        if($result.exitCode -ne 0){throw 'diagnostic-pristine-check-failed'}
    }
    $null=Stop-EzVmInstance -Root $root -InstanceName $Name -ShutdownTimeoutSeconds 120
    Save-GuestDiagnosticLogs
    Write-Host ('DIAGNOSTIC_PHASE=stopped; instance='+$Name)
}
$workloadFailed=$true
try{
    Write-Host 'DIAGNOSTIC_ONLY=not-full-qualification'
    Write-Host 'DIAGNOSTIC_PHASE=install-runtime'
    $null=Install-EzVmQemuRuntime -Root $root
    Write-Host 'DIAGNOSTIC_PHASE=acquire-source'
    $null=Invoke-EzVmSourceImageAcquire -Root $root
    Write-Host 'DIAGNOSTIC_PHASE=build-fresh-base'
    $base=Invoke-EzVmBaseBuild -Root $root -Accelerator whpx -BuildTimeoutSeconds 2400
    $null=New-EzVmManagedInstance -Root $root -InstanceName 'diagnostic-source' -BaseId $base.baseId
    if($Scenario -ceq 'release-order'){
        # Reproduce the intervening operations before the original failed
        # stateful first boot; this is still not the complete release scenario.
        Start-DiagnosticGuest -Name 'diagnostic-source' -WritePersistence
        Start-DiagnosticGuest -Name 'diagnostic-source' -CheckPersistence
        Write-Host 'DIAGNOSTIC_PHASE=ordered-copy-export-import'
        $null=Copy-EzVmManagedInstance -Root $root -SourceInstanceName 'diagnostic-source' -DestinationInstanceName 'diagnostic-fresh-1' -Mode fresh
        $null=Copy-EzVmManagedInstance -Root $root -SourceInstanceName 'diagnostic-source' -DestinationInstanceName 'diagnostic-stateful-1' -Mode stateful
        $export=Export-EzVmManagedInstance -Root $root -InstanceName 'diagnostic-source' -DestinationDirectory (Join-Path $root 'diagnostic export')
        $null=Import-EzVmManagedInstance -Root $root -InstanceName 'diagnostic-imported' -ImagePath $export.Image -ManifestPath $export.ManifestPath -Profile light
        Start-DiagnosticGuest -Name 'diagnostic-fresh-1' -CheckPristine
        Write-Host 'DIAGNOSTIC_PHASE=ordered-source-reset'
        $null=Reset-EzVmManagedInstance -Root $root -InstanceName 'diagnostic-source'
        Start-DiagnosticGuest -Name 'diagnostic-source' -CheckPristine
        Start-DiagnosticGuest -Name 'diagnostic-stateful-1' -CheckPersistence
        Start-DiagnosticGuest -Name 'diagnostic-imported' -CheckPersistence
    }else{
      Start-DiagnosticGuest -Name 'diagnostic-source'
      foreach($number in 1..3){
        foreach($mode in @('fresh','stateful')){
            $name='diagnostic-'+$mode+'-'+$number
            Write-Host ('DIAGNOSTIC_PHASE=clone; mode='+$mode+'; instance='+$name)
            $null=Copy-EzVmManagedInstance -Root $root -SourceInstanceName 'diagnostic-source' -DestinationInstanceName $name -Mode $mode
            Start-DiagnosticGuest -Name $name
        }
      }
    }
    Write-Host 'DIAGNOSTIC_PHASE=completed-no-full-qualification-claim'
    $workloadFailed=$false
}finally{
    $cleanupFailed=$false
    try{Save-GuestDiagnosticLogs}catch{$cleanupFailed=$true;Write-Host 'DIAGNOSTIC_SNAPSHOT_UNAVAILABLE=private-evidence'}
    foreach($name in $active){try{$null=Stop-EzVmInstance -Root $root -InstanceName $name -ShutdownTimeoutSeconds 30}catch{$cleanupFailed=$true;Write-Host ('DIAGNOSTIC_STOP_UNCONFIRMED='+$name)}}
    if($cleanupFailed -and -not $workloadFailed){throw 'diagnostic-cleanup-incomplete'}
}
