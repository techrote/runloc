#requires -Version 5.1
[CmdletBinding()]param([Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{40}$')][string]$ExpectedCommit)
$ErrorActionPreference='Stop'
$env:PSModulePath=[IO.Path]::Combine($PSHOME,'Modules')
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
Get-PilotSourceIdentity -Root ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))) -Repository 'https://github.com/techrote/runloc' -ExpectedCommit $ExpectedCommit|ConvertTo-Json -Depth 12
