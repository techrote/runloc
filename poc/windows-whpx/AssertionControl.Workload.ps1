#requires -Version 5.1
# Negative-only workload. Its expected result is a real failed guest assertion.
[CmdletBinding()]param([Parameter(Mandatory=$true)][string]$SourceRoot,
    [Parameter(Mandatory=$true)][string]$Fixture)
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
$root=Join-Path $Fixture 'assertion control'
$null=New-Item -ItemType Directory -Path $root
foreach($relative in @('ezvm.ps1','src','config','manifests','guest','scripts','tools')){
    Copy-Item -LiteralPath (Join-Path $SourceRoot $relative) -Destination $root -Recurse
}
Import-Module (Join-Path $root 'src/EzVm/EzVm.psd1') -Force
. (Join-Path $SourceRoot 'scripts/QualificationResources.ps1')
Set-EzVmQualificationResources -Root $root -Cpus 6
$created=$false
try{
    $null=Install-EzVmQemuRuntime -Root $root
    $null=Invoke-EzVmSourceImageAcquire -Root $root
    $base=Invoke-EzVmBaseBuild -Root $root -Accelerator tcg -BuildTimeoutSeconds 2400
    $null=New-EzVmManagedInstance -Root $root -InstanceName 'assertion-negative' -BaseId $base.baseId -Profile light
    $created=$true
    $ready=Start-EzVmReadyInstance -Root $root -InstanceName 'assertion-negative' -Accelerator tcg -ReadyTimeoutSeconds 900
    $cpu=Invoke-EzVmExec -Root $root -InstanceName 'assertion-negative' -Command @('getconf','_NPROCESSORS_ONLN') -TimeoutSeconds 60
    if($ready.state -cne 'READY' -or $ready.accelerator -cne 'tcg' -or $cpu.exitCode -ne 0 -or $cpu.stdout.Trim() -cne '6'){
        throw 'assertion-control-authenticated-ready-or-profile-failed'
    }
    Write-Host 'ASSERTION_CONTROL_AUTHENTICATED_READY=tcg;CPUS=6'
    # Fixed false assertion, executed over the real authenticated guest channel.
    # No injected candidate patch, credential, alternate command or success mode.
    $result=Invoke-EzVmExec -Root $root -InstanceName 'assertion-negative' -Command @('test','1','-eq','2') -TimeoutSeconds 60
    if($result.exitCode -ne 1 -or $result.stdout -cne '' -or $result.stderr -cne ''){
        throw 'assertion-control-unexpected-command-result'
    }
    Write-Host 'ASSERTION_CONTROL_ACTUAL_GUEST_EXIT=1'
    Write-Host 'ASSERTION_CONTROL_DELIBERATE_ASSERTION=FAILED'
}finally{
    if($created){
        $null=Stop-EzVmInstance -Root $root -InstanceName 'assertion-negative' -ShutdownTimeoutSeconds 120
        $paths=Get-EzVmInstanceRuntimePaths -Root $root -InstanceName 'assertion-negative'
        $runtime=[IO.File]::ReadAllText($paths.Runtime)|ConvertFrom-Json
        if($runtime.state -cne 'STOPPED' -or $runtime.accelerator -cne 'tcg'){throw 'assertion-control-stop-unconfirmed'}
        Write-Host 'ASSERTION_CONTROL_GUEST_STOPPED=tcg'
    }
}
# Expected failure stays an actual nonzero harness exit and red Actions job.
throw 'deliberate-functional-assertion-failed'
