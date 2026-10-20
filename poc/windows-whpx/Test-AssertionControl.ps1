#requires -Version 5.1
$ErrorActionPreference='Stop';$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
. (Join-Path $PSScriptRoot 'AssertionControl.Common.ps1')
$signals=@('ASSERTION_CONTROL_AUTHENTICATED_READY=tcg;CPUS=6','ASSERTION_CONTROL_ACTUAL_GUEST_EXIT=1',
    'ASSERTION_CONTROL_DELIBERATE_ASSERTION=FAILED','ASSERTION_CONTROL_GUEST_STOPPED=tcg')
function New-ControlResult {
    param([int]$Code,[string[]]$Lines)
    return @{exitCode=$Code;activeProcesses=0;childExited=$true;forced=$false;timedOut=$false;cancelled=$false;
        outputFailed=$false;outputOverflow=$false;records=@($Lines|ForEach-Object {@{Text=$_}})}
}
$child=New-ControlResult 1 $signals
$preflight=New-ControlResult 0 @('RUNLOC_EXACT_ACL_PREFLIGHT=PASS')
if(-not (Test-AssertionControlObserved $child $preflight $true $true)){throw 'complete-control-rejected'}
$count=1
foreach($field in @('forced','timedOut','cancelled','outputFailed','outputOverflow')){
    foreach($which in @('child','preflight')){
        $bad=(Get-Variable -Name $which -ValueOnly).Clone();$bad[$field]=$true
        $observed=if($which -ceq 'child'){Test-AssertionControlObserved $bad $preflight $true $true}else{Test-AssertionControlObserved $child $bad $true $true}
        if($observed){throw 'failed-or-incomplete-result-accepted'};$count++
    }
}
foreach($field in @('exitCode','activeProcesses','childExited','forced','timedOut','cancelled','outputFailed','outputOverflow')){
    $bad=$child.Clone();$bad.Remove($field)
    if(Test-AssertionControlObserved $bad $preflight $true $true){throw 'partial-result-accepted'};$count++
}
foreach($badLines in @(@($signals[1..3]),@($signals+$signals[0]),@($signals[1],$signals[0],$signals[2],$signals[3]),@('PASS'))){
    $bad=New-ControlResult 1 $badLines
    if(Test-AssertionControlObserved $bad $preflight $true $true){throw 'missing-duplicate-reordered-or-forged-signals-accepted'};$count++
}
foreach($code in @(0,7)){
    $bad=New-ControlResult $code $signals
    if(Test-AssertionControlObserved $bad $preflight $true $true){throw 'wrong-actual-exit-accepted'};$count++
}
foreach($changed in @(@{activeProcesses=1},@{childExited=$false},@{activeProcesses='0'},@{exitCode='1'})){
    $bad=$child.Clone();foreach($key in $changed.Keys){$bad[$key]=$changed[$key]}
    if(Test-AssertionControlObserved $bad $preflight $true $true){throw 'unresolved-or-untyped-result-accepted'};$count++
}
$badPreflight=New-ControlResult 1 @('RUNLOC_EXACT_ACL_PREFLIGHT=PASS')
if(Test-AssertionControlObserved $child $badPreflight $true $true){throw 'failed-preflight-pass-text-accepted'};$count++
if(Test-AssertionControlObserved $child $preflight $false $true){throw 'source-change-accepted'};$count++
if(Test-AssertionControlObserved $child $preflight $true $false){throw 'cleanup-failure-accepted'};$count++
$sandbox=Join-Path ([IO.Path]::GetTempPath()) ('runloc-assertion-workload-'+[Guid]::NewGuid().ToString('N'))
$source=Join-Path $sandbox 'source'
[void][IO.Directory]::CreateDirectory($source)
try{
    foreach($directory in @('src/EzVm','config','manifests','guest','scripts','tools')){[void][IO.Directory]::CreateDirectory((Join-Path $source $directory))}
    [IO.File]::WriteAllText((Join-Path $source 'ezvm.ps1'),'# synthetic fixture')
    [IO.File]::WriteAllText((Join-Path $source 'src/EzVm/EzVm.psd1'),"@{RootModule='EzVm.psm1';ModuleVersion='1.0.0';FunctionsToExport='*'}")
    [IO.File]::WriteAllText((Join-Path $source 'scripts/QualificationResources.ps1'),'function Set-EzVmQualificationResources {param($Root,$Cpus) if($Cpus -ne 6){throw ''wrong-cpus''}}')
    [IO.File]::WriteAllText((Join-Path $source 'src/EzVm/EzVm.psm1'),@'
function Install-EzVmQemuRuntime {param($Root)}
function Invoke-EzVmSourceImageAcquire {param($Root)}
function Invoke-EzVmBaseBuild {param($Root,$Accelerator,$BuildTimeoutSeconds) if($Accelerator -cne 'tcg' -or $BuildTimeoutSeconds -ne 2400){throw 'wrong-base-policy'};return @{baseId='synthetic'}}
function New-EzVmManagedInstance {param($Root,$InstanceName,$BaseId,$Profile) if($Profile -cne 'light'){throw 'wrong-profile'}}
function Start-EzVmReadyInstance {param($Root,$InstanceName,$Accelerator,$ReadyTimeoutSeconds) if($Accelerator -cne 'tcg' -or $ReadyTimeoutSeconds -ne 900){throw 'wrong-ready-policy'};return @{state='READY';accelerator='tcg'}}
function Invoke-EzVmExec {
    param($Root,$InstanceName,$Command,$TimeoutSeconds)
    if($TimeoutSeconds -ne 60){throw 'wrong-command-bound'}
    $mode=[IO.File]::ReadAllText((Join-Path $Root 'tools/testmode.txt'))
    if(($Command -join ' ') -ceq 'getconf _NPROCESSORS_ONLN'){return @{exitCode=0;stdout=$(if($mode -ceq 'bad-cpu'){'5'}else{'6'});stderr=''}}
    if(($Command -join ' ') -cne 'test 1 -eq 2'){throw 'false-assertion-command-changed'}
    return @{exitCode=$(if($mode -ceq 'bad-assertion-exit'){0}else{1});stdout='';stderr=''}
}
function Stop-EzVmInstance {param($Root,$InstanceName,$ShutdownTimeoutSeconds) if($ShutdownTimeoutSeconds -ne 120){throw 'wrong-stop-bound'};[IO.File]::WriteAllText((Join-Path $Root 'control-runtime.json'),'{"state":"STOPPED","accelerator":"tcg"}')}
function Get-EzVmInstanceRuntimePaths {param($Root,$InstanceName) return @{Runtime=(Join-Path $Root 'control-runtime.json')}}
'@)
    foreach($mode in @('expected-failure','bad-cpu','bad-assertion-exit')){
        [IO.File]::WriteAllText((Join-Path $source 'tools/testmode.txt'),$mode)
        $fixture=Join-Path $sandbox $mode;[void][IO.Directory]::CreateDirectory($fixture)
        $records=New-Object 'System.Collections.Generic.List[object]';$failure=''
        try{& (Join-Path $PSScriptRoot 'AssertionControl.Workload.ps1') -SourceRoot $source -Fixture $fixture 6>&1|ForEach-Object {$records.Add(@{Text=$_.ToString()})}}
        catch{$failure=$_.Exception.Message}
        $observedChild=New-ControlResult 1 @();$observedChild.records=$records.ToArray()
        $observed=Test-AssertionControlObserved $observedChild $preflight $true $true
        if($observed -ne ($mode -ceq 'expected-failure') -or ($observed -and $failure -cne 'deliberate-functional-assertion-failed')){throw 'actual-workload-failure-routing-incorrect'}
        $count++
    }
}finally{
    Remove-Module EzVm -Force -ErrorAction SilentlyContinue
    $resolved=[IO.Path]::GetFullPath($sandbox)
    if([IO.Path]::GetDirectoryName($resolved) -cne [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') -or (Split-Path $resolved -Leaf) -cnotmatch '^runloc-assertion-workload-[a-f0-9]{32}$'){throw 'synthetic-cleanup-root-invalid'}
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
Write-Host ('PASS: '+$count+' negative-only assertion observation controls; no guest or Actions execution')
