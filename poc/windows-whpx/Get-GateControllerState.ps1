#requires -Version 5.1
[CmdletBinding()]param([Parameter(Mandatory=$true)][string]$ConsoleRoot)
$ErrorActionPreference='Stop'
$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
$root=Assert-PilotPath -Path $ConsoleRoot
$started=[IO.File]::ReadAllText((Assert-PilotPath -Path (Join-Path $root 'controller-started.json') -File))|ConvertFrom-Json
if($started.processId -isnot [int] -or $started.processId -le 0){throw 'controller-owner-record-invalid'}
$process=Get-CimInstance Win32_Process -Filter ('ProcessId='+$started.processId)
$alive=$null -ne $process -and $process.Name -ceq 'powershell.exe' -and
    [Math]::Abs(($process.CreationDate.ToUniversalTime()-([DateTimeOffset]::Parse($started.createdUtc)).UtcDateTime).TotalMilliseconds) -lt 1
@{alive=[bool]$alive;observedUtc=[DateTime]::UtcNow.ToString('o')}|ConvertTo-Json -Compress
