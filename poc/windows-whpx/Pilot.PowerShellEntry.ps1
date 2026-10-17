#requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$InvocationBase64)

# The guard uses only Core/BCL operations. An accidental call or dot-source must
# refuse before changing the caller's process environment or reaching an exit.
. ([IO.Path]::Combine($PSScriptRoot, 'Pilot.Bootstrap.ps1'))
if (-not (Test-PilotEarlyDedicatedFileInvocation -CommandLine ([Environment]::GetCommandLineArgs()) -ExpectedScript $PSCommandPath -InvocationName $MyInvocation.InvocationName)) {
    throw 'Launch Pilot.PowerShellEntry.ps1 only as its dedicated -NoProfile -NonInteractive -File process.'
}
[Environment]::SetEnvironmentVariable('PSModulePath', [IO.Path]::Combine($PSHOME, 'Modules'), [EnvironmentVariableTarget]::Process)
$ErrorActionPreference = 'Stop'

try {
    . ([IO.Path]::Combine($PSScriptRoot, 'Pilot.Common.ps1'))
    $invocation = Read-PilotPowerShellInvocation -InvocationBase64 $InvocationBase64
    $target = $invocation.TargetScript
    $parameters = $invocation.NamedParameters
    $positionalArguments = $invocation.PositionalArguments
    # Match a fresh -File target's default preferences and child script scope.
    # Production targets establish their own strict/error policies. A normal
    # return after a handled native nonzero exit is still a successful script.
    Set-StrictMode -Off
    $ErrorActionPreference = 'Continue'
    $global:LASTEXITCODE = 0
    & $target @parameters @positionalArguments
    $targetSucceeded = $?
    if (-not $targetSucceeded) {
        if ($LASTEXITCODE -is [int] -and $LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        exit 1
    }
    exit 0
}
catch {
    [Console]::Error.WriteLine('RUNLOC_POWERSHELL_ENTRY_FAILURE=' + $_.Exception.Message)
    exit 1
}
