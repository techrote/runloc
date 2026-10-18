#requires -Version 5.1
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')
. (Join-Path $PSScriptRoot 'Hosted.Common.ps1')
Import-PilotNative
$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$parent=Join-Path $temp ('runloc-hosted-fixture-'+[Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($parent)
$lease=$null;$removed=$false
function Write-HostedFixtureJson {param($Path,$Value)
    [void][IO.Directory]::CreateDirectory((Split-Path $Path -Parent))
    [IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 8))
}
try {
    $lease=New-PilotLease -EvidenceParent $parent -CandidateCommit ('b'*40) -ControllerCommit ('a'*40) -WorkParent ([Environment]::GetFolderPath('UserProfile'))
    New-PilotFixture -Lease $lease
    $work=Join-Path $lease.Fixture ('ezvm010 qualification '+[Guid]::NewGuid().ToString('N'))
    $candidate=Join-Path $parent 'candidate'
    $sourceBytes=[Text.Encoding]::UTF8.GetBytes('source')
    $baseBytes=[Text.Encoding]::UTF8.GetBytes('base')
    $toolBytes=[Text.Encoding]::UTF8.GetBytes('tool')
    $algorithm=[Security.Cryptography.SHA256]::Create()
    try {
        $sourceHash=([BitConverter]::ToString($algorithm.ComputeHash($sourceBytes))).Replace('-','').ToLowerInvariant()
        $baseHash=([BitConverter]::ToString($algorithm.ComputeHash($baseBytes))).Replace('-','').ToLowerInvariant()
        $toolHash=([BitConverter]::ToString($algorithm.ComputeHash($toolBytes))).Replace('-','').ToLowerInvariant()
    } finally {$algorithm.Dispose()}
    Write-HostedFixtureJson (Join-Path $candidate 'manifests/ubuntu-noble-amd64.json') @{filename='source.img'}
    Write-HostedFixtureJson (Join-Path $candidate 'manifests/qemu-windows.json') @{whpxResetOverlay=@{files=@(
        @{name='qemu-system-x86_64.exe';sha256=$toolHash},@{name='qemu-img.exe';sha256=$toolHash})}}
    foreach($rootName in @('root A with spaces','moved root B with spaces')){
        $root=Join-Path $work $rootName
        Write-HostedFixtureJson (Join-Path $root 'runtime/bases/base-test/manifest.json') @{
            build=@{accelerator='tcg'};source=@{imageSha256=$sourceHash};baseSha256=$baseHash}
        [IO.File]::WriteAllBytes((Join-Path $root 'runtime/bases/base-test/base.qcow2'),$baseBytes)
        $cache=Join-Path $root 'runtime/cache/source-images';[void][IO.Directory]::CreateDirectory($cache)
        [IO.File]::WriteAllBytes((Join-Path $cache 'source.img'),$sourceBytes)
        $qemu=Join-Path $root 'runtime/qemu';[void][IO.Directory]::CreateDirectory($qemu)
        foreach($name in @('qemu-system-x86_64.exe','qemu-img.exe')){[IO.File]::WriteAllBytes((Join-Path $qemu $name),$toolBytes)}
        foreach($name in @('ezvm010-source','ezvm012-secondary','ezvm012-fresh','ezvm010-stateful','ezvm010-imported')){
            $memory=if($name -cin @('ezvm010-imported','ezvm012-secondary')){4096}else{8192}
            Write-HostedFixtureJson (Join-Path $root ('runtime/instances/'+$name+'/runtime.json')) @{
                instanceName=$name;state='STOPPED';accelerator='tcg';launchId=('d'*32)}
            Write-HostedFixtureJson (Join-Path $root ('runtime/instances/'+$name+'/instance.json')) @{cpus=6;memoryMiB=$memory}
        }
    }
    $observedEvents=@(@{kind='identity';name='base-id';value='base-test'},@{kind='identity';name='SOURCE_SHA256';value=$sourceHash},
        @{kind='identity';name='qemu-version';value='1.2.3'})
    $clock=[Diagnostics.Stopwatch]::StartNew()
    $arguments=@{Lease=$lease;Events=$observedEvents;ExpectedImageSha256=$sourceHash;ExpectedQemuVersion='1.2.3';Clock=$clock;DeadlineSeconds=60;CandidateRoot=$candidate}
    $identity=Get-HostedFixtureIdentity @arguments
    if($identity.guests.Count -ne 10 -or $identity.baseImageSha256 -cne $baseHash){throw 'valid-hosted-fixture-rejected'}
    $count=1
    $root=Join-Path $work 'moved root B with spaces'
    foreach($case in @('memory','accelerator','base','tool','source')){
        $path=switch($case){
            'memory' {Join-Path $root 'runtime/instances/ezvm010-source/instance.json'}
            'accelerator' {Join-Path $root 'runtime/instances/ezvm010-source/runtime.json'}
            'base' {Join-Path $root 'runtime/bases/base-test/base.qcow2'}
            'tool' {Join-Path $root 'runtime/qemu/qemu-img.exe'}
            'source' {Join-Path $root 'runtime/cache/source-images/source.img'}
        }
        $original=[IO.File]::ReadAllBytes($path)
        try {
            if($case -eq 'memory'){Write-HostedFixtureJson $path @{cpus=6;memoryMiB=4096}}
            elseif($case -eq 'accelerator'){Write-HostedFixtureJson $path @{instanceName='ezvm010-source';state='STOPPED';accelerator='whpx';launchId=('d'*32)}}
            else {[IO.File]::WriteAllText($path,'corrupt')}
            $rejected=$false;try {$null=Get-HostedFixtureIdentity @arguments}catch {$rejected=$true}
            if(-not $rejected){throw ('tampered-hosted-fixture-accepted-'+$case)};$count++
        } finally {[IO.File]::WriteAllBytes($path,$original)}
    }
    Write-Host ('Hosted fixture audit controls passed: '+$count)
} finally {
    if($null -ne $lease){
        try {Remove-PilotFixture -Lease $lease -Clock ([Diagnostics.Stopwatch]::StartNew()) -DeadlineSeconds 30 -OwnedProcessesExited $true;$removed=$true}
        finally {$lease.Lock.Dispose()}
    }
    $resolved=[IO.Path]::GetFullPath($parent)
    if(-not $resolved.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or (Split-Path $resolved -Leaf) -cnotmatch '^runloc-hosted-fixture-[a-f0-9]{32}$'){throw 'hosted-test-cleanup-path-invalid'}
    if($removed -and [IO.Directory]::Exists($resolved)){Remove-Item -LiteralPath $resolved -Recurse -Force}
}
