#requires -Version 5.1
$ErrorActionPreference='Stop'
$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
$folder=Join-Path ([IO.Path]::GetTempPath()) ('runloc-gate-process-'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $folder
$child=$null
try{
    Set-PilotPrivateDirectory -Path $folder
    $start=New-Object Diagnostics.ProcessStartInfo
    $start.FileName=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $start.Arguments='-NoLogo -NoProfile -NonInteractive -Command "Start-Sleep -Seconds 60"'
    $start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $child=[Diagnostics.Process]::Start($start)
    $created=$child.StartTime.ToUniversalTime()
    $path=Join-Path $folder 'controller-started.json'
    [IO.File]::WriteAllText($path,(@{processId=$child.Id;createdUtc=$created.ToString('o')}|ConvertTo-Json))
    $record=(& (Join-Path $PSScriptRoot 'Get-GateControllerState.ps1') -ConsoleRoot $folder)|ConvertFrom-Json
    if($record.alive -isnot [bool] -or -not $record.alive){throw 'live-owned-controller-not-observed'}
    Write-Host 'PASS gate process: actual live controller generation including CIM precision'
    [IO.File]::WriteAllText($path,(@{processId=$child.Id;createdUtc=$created.AddSeconds(-1).ToString('o')}|ConvertTo-Json))
    $record=(& (Join-Path $PSScriptRoot 'Get-GateControllerState.ps1') -ConsoleRoot $folder)|ConvertFrom-Json
    if($record.alive -isnot [bool] -or $record.alive){throw 'different-process-generation-accepted'}
    if($child.HasExited){throw 'read-only-adapter-terminated-child'}
    Write-Host 'PASS gate process: wrong generation rejected without killing process'
    [IO.File]::WriteAllText($path,(@{processId=$child.Id;createdUtc=$created.ToString('o')}|ConvertTo-Json))
    $child.Kill();$child.WaitForExit()
    $record=(& (Join-Path $PSScriptRoot 'Get-GateControllerState.ps1') -ConsoleRoot $folder)|ConvertFrom-Json
    if($record.alive -isnot [bool] -or $record.alive){throw 'exited-controller-accepted'}
    Write-Host 'PASS gate process: actual exited controller observed absent'
}finally{
    if($null -ne $child){if(-not $child.HasExited){$child.Kill();$child.WaitForExit()};$child.Dispose()}
    # This exact newly created directory contains only this test's one record.
    if([IO.File]::Exists((Join-Path $folder 'controller-started.json'))){[IO.File]::Delete((Join-Path $folder 'controller-started.json'))}
    [IO.Directory]::Delete($folder,$false)
}
