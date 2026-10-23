#requires -Version 5.1
function Test-AssertionControlObserved {
    param([object]$Child,[object]$Preflight,[bool]$SourceUnchanged,[bool]$FixtureRemoved)
    try{
        foreach($result in @($Child,$Preflight)){
            if($null -eq $result){return $false}
            foreach($field in @('childExited','forced','timedOut','cancelled','outputFailed','outputOverflow')){
                if($result.$field -isnot [bool]){return $false}
            }
            if(($result.exitCode -isnot [int] -and $result.exitCode -isnot [long]) -or
                ($result.activeProcesses -isnot [int] -and $result.activeProcesses -isnot [long] -and $result.activeProcesses -isnot [uint32])){return $false}
            if(-not $result.childExited -or
                $result.activeProcesses -ne 0 -or $result.forced -or $result.timedOut -or $result.cancelled -or
                $result.outputFailed -or $result.outputOverflow){return $false}
        }
        if($Child.exitCode -ne 1 -or $Preflight.exitCode -ne 0 -or -not $SourceUnchanged -or -not $FixtureRemoved){return $false}
        if(@($Preflight.records|Where-Object {$_.Text -ceq 'RUNLOC_EXACT_ACL_PREFLIGHT=PASS'}).Count -ne 1){return $false}
        $expected=@('ASSERTION_CONTROL_AUTHENTICATED_READY=tcg;CPUS=6','ASSERTION_CONTROL_ACTUAL_GUEST_EXIT=1',
            'ASSERTION_CONTROL_DELIBERATE_ASSERTION=FAILED','ASSERTION_CONTROL_GUEST_STOPPED=tcg')
        $observed=@($Child.records|Where-Object {$_.Text.StartsWith('ASSERTION_CONTROL_')}|ForEach-Object {$_.Text})
        return ($observed.Count -eq $expected.Count -and ($observed -join "`n") -ceq ($expected -join "`n"))
    }catch{return $false}
}
