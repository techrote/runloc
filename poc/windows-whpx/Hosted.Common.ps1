#requires -Version 5.1
# Separate TCG adapter: never broadens the physical WHPX oracle.
function Test-GateHostedOutcome {
    param([object]$Child,[object[]]$Events,[object]$Telemetry,[bool]$SourceUnchanged)
    $expected=@($script:PilotMarkers|Where-Object {$_ -cne 'EZVM010_WHPX_EXECUTION'})
    $bad=@($expected|Where-Object {$marker=$_;@($Events|Where-Object {$_.kind -ceq 'marker' -and $_.name -ceq $marker -and $_.value -ceq 'PASS'}).Count -ne 1})
    if($Child.exitCode -ne 0 -or -not $Child.childExited -or $null -eq $Child.activeProcesses -or $Child.activeProcesses -ne 0 -or
        $Child.forced -or $Child.outputOverflow -or $Child.outputFailed -or -not $SourceUnchanged -or $bad.Count -ne 0 -or
        $null -eq $Telemetry -or $Telemetry.complete -ne $true){return $false}
    foreach($kind in @('source-image','prepared-base','qemu-system','qemu-img')){
        if(@($Telemetry.identities|Where-Object {$_.kind -ceq $kind -and $_.sha256 -cmatch '^[a-f0-9]{64}$'}).Count -ne 1){return $false}
    }
    $accelerators=@($Events|Where-Object {$_.kind -ceq 'accelerator'})
    $cpus=@($Events|Where-Object {$_.kind -ceq 'guest-cpus'})
    return @($Events|Where-Object {$_.kind -ceq 'failure'}).Count -eq 0 -and
        @($Events|Where-Object {$_.kind -ceq 'marker'}).Count -eq 23 -and
        @($Events|Where-Object {$_.kind -ceq 'phase' -and $_.name -ceq 'guest_ready'}).Count -eq 8 -and
        $cpus.Count -eq 8 -and @($cpus|Where-Object {$_.value -cne '6'}).Count -eq 0 -and
        $accelerators.Count -eq 1 -and $accelerators[0].value -ceq 'tcg' -and
        @($Events|Where-Object {$_.kind -ceq 'capability' -and $_.name -ceq 'whpx' -and $_.value -ceq 'SKIP'}).Count -eq 1
}
