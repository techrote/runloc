#requires -Version 5.1
# Separate TCG adapter: never broadens the physical WHPX oracle.
function Test-HostedProcessResolved {
    param([bool]$Attempted,[object]$Result)
    if(-not $Attempted){return $true}
    return $null -ne $Result -and $Result.childExited -is [bool] -and $Result.childExited -and
        ($Result.activeProcesses -is [int] -or $Result.activeProcesses -is [long] -or $Result.activeProcesses -is [uint32]) -and $Result.activeProcesses -eq 0
}
function Test-GateHostedOutcome {
    param([object]$Child,[object[]]$Events,[object]$Telemetry,[bool]$SourceUnchanged,[object]$Identities)
    try {
    if($Child.exitCode -isnot [int] -and $Child.exitCode -isnot [long]){return $false}
    if($Child.activeProcesses -isnot [int] -and $Child.activeProcesses -isnot [long] -and $Child.activeProcesses -isnot [uint32]){return $false}
    foreach($field in @('childExited','forced','outputOverflow','outputFailed')){if($Child.$field -isnot [bool]){return $false}}
    $expected=@($script:PilotMarkers|Where-Object {$_ -cne 'EZVM010_WHPX_EXECUTION'})
    $bad=@($expected|Where-Object {$marker=$_;@($Events|Where-Object {$_.kind -ceq 'marker' -and $_.name -ceq $marker -and $_.value -ceq 'PASS'}).Count -ne 1})
    if($Child.exitCode -ne 0 -or -not $Child.childExited -or $null -eq $Child.activeProcesses -or $Child.activeProcesses -ne 0 -or
        $Child.forced -or $Child.outputOverflow -or $Child.outputFailed -or -not $SourceUnchanged -or $bad.Count -ne 0 -or
        $null -eq $Telemetry -or $Telemetry.complete -ne $true){return $false}
    foreach($kind in @('source-image','prepared-base','qemu-system','qemu-img')){
        if(@($Telemetry.identities|Where-Object {$_.kind -ceq $kind -and $_.sha256 -cmatch '^[a-f0-9]{64}$'}).Count -ne 1){return $false}
    }
    if($null -eq $Identities -or @($Identities.guests).Count -ne 10){return $false}
    $bindings=@{'source-image'=$Identities.sourceImageSha256;'prepared-base'=$Identities.baseImageSha256}
    foreach($tool in @('qemu-system','qemu-img')){
        $name=if($tool -ceq 'qemu-system'){'qemu-system-x86_64.exe'}else{'qemu-img.exe'}
        $found=@($Identities.qemuBinaries|Where-Object {$_.name -ceq $name})
        if($found.Count -ne 1){return $false};$bindings[$tool]=$found[0].sha256
    }
    foreach($kind in $bindings.Keys){if(@($Telemetry.identities|Where-Object {$_.kind -ceq $kind})[0].sha256 -cne $bindings[$kind]){return $false}}
    foreach($root in @('A','B')){foreach($name in @('ezvm010-source','ezvm012-secondary','ezvm012-fresh','ezvm010-stateful','ezvm010-imported')){
        $guest=@($Identities.guests|Where-Object {$_.root -ceq $root -and $_.name -ceq $name})
        $memory=if($name -cin @('ezvm010-imported','ezvm012-secondary')){4096}else{8192}
        if($guest.Count -ne 1 -or $guest[0].state -cne 'STOPPED' -or $guest[0].accelerator -cne 'tcg' -or
            $guest[0].cpus -ne 6 -or $guest[0].memoryMiB -ne $memory -or $guest[0].launchId -cnotmatch '^[a-f0-9]{32}$'){return $false}
    }}
    $begin=@($Events|Where-Object {$_.kind -ceq 'boundary' -and $_.name -ceq 'STARTED_AT'})
    $end=@($Events|Where-Object {$_.kind -ceq 'boundary' -and $_.name -ceq 'COMPLETED_AT'})
    if($begin.Count -ne 1 -or $end.Count -ne 1 -or $begin[0].seconds -ge $end[0].seconds){return $false}
    $last=-1.0
    foreach($event in $Events){
        if($event.seconds -isnot [double] -and $event.seconds -isnot [int] -and $event.seconds -isnot [long] -and $event.seconds -isnot [decimal]){return $false}
        if([double]::IsNaN([double]$event.seconds) -or [double]::IsInfinity([double]$event.seconds) -or $event.seconds -lt $last){return $false}
        $last=$event.seconds
        if($event.kind -cin @('marker','accelerator','guest-cpus') -and ($event.seconds -le $begin[0].seconds -or $event.seconds -ge $end[0].seconds)){return $false}
    }
    $accelerators=@($Events|Where-Object {$_.kind -ceq 'accelerator'})
    $cpus=@($Events|Where-Object {$_.kind -ceq 'guest-cpus'})
    $ready=@($Events|Where-Object {$_.kind -ceq 'phase' -and $_.name -ceq 'guest_ready'})
    $names=@('ezvm010-source','ezvm012-secondary','ezvm010-source','ezvm012-fresh','ezvm010-source','ezvm010-stateful','ezvm010-imported','ezvm010-stateful')
    if($ready.Count -ne 8 -or $cpus.Count -ne 8){return $false}
    for($index=0;$index -lt 8;$index++){
        if($ready[$index].value -cne $names[$index] -or $cpus[$index].name -cne $names[$index] -or
            $cpus[$index].seconds -gt $ready[$index].seconds -or ($index -gt 0 -and $cpus[$index].seconds -le $ready[$index-1].seconds)){return $false}
    }
    return @($Events|Where-Object {$_.kind -ceq 'failure'}).Count -eq 0 -and
        @($Events|Where-Object {$_.kind -ceq 'marker'}).Count -eq 23 -and
        @($Events|Where-Object {$_.kind -ceq 'phase' -and $_.name -ceq 'guest_ready'}).Count -eq 8 -and
        $cpus.Count -eq 8 -and @($cpus|Where-Object {$_.value -cne '6'}).Count -eq 0 -and
        $accelerators.Count -eq 1 -and $accelerators[0].value -ceq 'tcg' -and
        @($Events|Where-Object {$_.kind -ceq 'capability' -and $_.name -ceq 'whpx' -and $_.value -ceq 'SKIP'}).Count -eq 1
    } catch {return $false}
}

function Get-HostedFixtureIdentity {
    param([object]$Lease, [object[]]$Events, [string]$ExpectedImageSha256, [string]$ExpectedQemuVersion,
        [Diagnostics.Stopwatch]$Clock, [double]$DeadlineSeconds, [string]$CandidateRoot)
    Assert-PilotLease -Lease $Lease
    $qemu=[IO.File]::ReadAllText((Join-Path $CandidateRoot 'manifests/qemu-windows.json'))|ConvertFrom-Json
    $image=[IO.File]::ReadAllText((Join-Path $CandidateRoot 'manifests/ubuntu-noble-amd64.json'))|ConvertFrom-Json
    $children = @([IO.Directory]::EnumerateDirectories($Lease.Fixture))
    if ($children.Count -ne 1 -or (Split-Path $children[0] -Leaf) -cnotmatch '^ezvm010 qualification [a-f0-9]{32}$') { throw 'fixture-root-count-or-name' }
    $work = Assert-PilotPath -Path $children[0]
    $baseEvents = @($Events | Where-Object { $_.kind -ceq 'identity' -and $_.name -ceq 'base-id' })
    $sourceEvents = @($Events | Where-Object { $_.kind -ceq 'identity' -and $_.name -ceq 'SOURCE_SHA256' })
    $toolEvents = @($Events | Where-Object { $_.kind -ceq 'identity' -and $_.name -ceq 'qemu-version' })
    if ($baseEvents.Count -ne 1 -or $sourceEvents.Count -ne 1 -or $toolEvents.Count -ne 1 -or
        $sourceEvents[0].value -cne $ExpectedImageSha256 -or $toolEvents[0].value -cne $ExpectedQemuVersion) { throw 'fixture-identity-events-invalid' }
    $roots = @('root A with spaces', 'moved root B with spaces')
    $binaries = @(); $guests = @(); $baseDigest = ''
    foreach ($rootName in $roots) {
        $root = Assert-PilotPath -Path (Join-Path $work $rootName)
        if ([IO.Directory]::Exists((Join-Path $work 'source root A held for relocation'))) { throw 'fixture-source-root-not-restored' }
        $manifestPath = Assert-PilotPath -Path (Join-Path $root ('runtime/bases/' + $baseEvents[0].value + '/manifest.json')) -File
        $manifest = [IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
        if ($manifest.build.accelerator -cne 'tcg' -or $manifest.source.imageSha256 -cne $ExpectedImageSha256 -or
            $manifest.baseSha256 -cnotmatch '^[a-f0-9]{64}$') { throw 'fixture-base-accelerator-or-identity-mismatch' }
        if ($baseDigest -and $baseDigest -cne $manifest.baseSha256) { throw 'fixture-base-relocation-mismatch' }
        $baseDigest = $manifest.baseSha256
        $basePath=Assert-PilotPath -Path (Join-Path (Split-Path $manifestPath -Parent) 'base.qcow2') -File
        $sourcePath=Assert-PilotPath -Path (Join-Path $root ('runtime/cache/source-images/'+$image.filename)) -File
        if((Get-PilotDigest $basePath) -cne $baseDigest -or (Get-PilotDigest $sourcePath) -cne $ExpectedImageSha256){throw 'hosted-image-bytes-mismatch'}
        foreach ($toolName in @('qemu-system-x86_64.exe', 'qemu-img.exe')) {
            Assert-PilotDeadline -Clock $Clock -DeadlineSeconds $DeadlineSeconds
            $toolPath = Assert-PilotPath -Path (Join-Path $root ('runtime/qemu/' + $toolName)) -File
            $digest = Get-PilotDigest -Path $toolPath
            $pins=@($qemu.whpxResetOverlay.files|Where-Object {$_.name -ceq $toolName})
            if($pins.Count -ne 1 -or $pins[0].sha256 -cne $digest){throw 'hosted-tool-pin-mismatch'}
            if ($rootName -ceq $roots[0]) { $binaries += [ordered]@{ name = $toolName; sha256 = $digest } }
            elseif ($digest -cne @($binaries | Where-Object { $_.name -ceq $toolName })[0].sha256) { throw 'fixture-relocated-tool-mismatch' }
        }
        foreach ($name in @('ezvm010-source', 'ezvm010-stateful', 'ezvm010-imported', 'ezvm012-secondary', 'ezvm012-fresh')) {
            $runtimePath = Assert-PilotPath -Path (Join-Path $root ('runtime/instances/' + $name + '/runtime.json')) -File
            $runtime = [IO.File]::ReadAllText($runtimePath) | ConvertFrom-Json
            if ($runtime.instanceName -cne $name -or $runtime.state -cne 'STOPPED' -or $runtime.accelerator -cne 'tcg' -or
                $runtime.launchId -cnotmatch '^[a-f0-9]{32}$') { throw 'fixture-guest-not-stopped-or-accelerator-mismatch' }
            $intentPath = Assert-PilotPath -Path (Join-Path $root ('runtime/instances/' + $name + '/instance.json')) -File
            $intent = [IO.File]::ReadAllText($intentPath) | ConvertFrom-Json
            $memory=if($name -cin @('ezvm010-imported','ezvm012-secondary')){4096}else{8192}
            if ($intent.cpus -ne 6 -or $intent.memoryMiB -ne $memory) { throw 'hosted-guest-resource-mismatch' }
            $guests += [ordered]@{ root = $(if ($rootName -ceq $roots[0]) { 'A' } else { 'B' }); name = $name;
                state = 'STOPPED'; accelerator = 'tcg'; launchId = $runtime.launchId; cpus = [int]$intent.cpus; memoryMiB = [int]$intent.memoryMiB }
        }
    }
    return [pscustomobject][ordered]@{ expectedImageSha256 = $ExpectedImageSha256; sourceImageSha256 = $sourceEvents[0].value;
        baseImageSha256 = $baseDigest; baseId = $baseEvents[0].value; qemuVersion = $ExpectedQemuVersion; qemuBinaries = $binaries; guests = $guests }
}
