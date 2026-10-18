#requires -Version 5.1
[CmdletBinding()]param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Runner.Common.ps1')
. (Join-Path $PSScriptRoot 'Test-ConsoleMonitor.ps1')
$passed = 0
function Assert-RunnerTest { param([bool]$Condition) if (-not $Condition) { throw 'runner-test-assertion' } }
function Assert-RunnerThrows { param([scriptblock]$Action) try { & $Action | Out-Null } catch { return }; throw 'expected-runner-refusal' }
function Test-RunnerCase { param([string]$Name, [scriptblock]$Action) & $Action; $script:passed++; Write-Host ('PASS runner: ' + $Name) }
$runnerName = 'runloc-' + ('a' * 32)

Test-RunnerCase 'routing rejects generic labels that could accept an unapproved ordinary job' {
    $runner = @{ name = $runnerName; labels = @(@{ name = $runnerName }) }
    Assert-RunnerRouting -Runner $runner -Name $runnerName
    foreach ($label in @('self-hosted', 'Windows', 'X64', 'ezvm-whpx')) {
        $runner.labels = @(@{ name = $runnerName }, @{ name = $label })
        Assert-RunnerThrows { Assert-RunnerRouting -Runner $runner -Name $runnerName }
    }
}

Test-RunnerCase 'an earlier green job cannot override later cancellation uncertain cleanup or a live child' {
    $good = @{ JobPassed = $true; Reason = 'job-completed'; Exited = $true; ActiveProcesses = 0; Forced = $false;
        RemoteAbsent = $true; FixtureRemoved = $true; BackingIntact = $true; SentinelIntact = $true; SourceIntact = $true; WorkflowCleanupConfirmed = $true }
    Assert-RunnerTest (Test-RunnerFinalOutcome @good)
    foreach ($reason in @('owner-cancelled', 'remote-cleanup-unconfirmed', 'runner-operation-failed')) {
        $good.Reason = $reason
        Assert-RunnerTest (-not (Test-RunnerFinalOutcome @good))
    }
    $good.Reason = 'job-completed'; $good.WorkflowCleanupConfirmed = $false
    Assert-RunnerTest (-not (Test-RunnerFinalOutcome @good))
    $good.WorkflowCleanupConfirmed = $true; $good.ActiveProcesses = 1
    Assert-RunnerTest (-not (Test-RunnerFinalOutcome @good))
}

Test-RunnerCase 'Actions association rejects another head rerun runner or multiple jobs despite successful prose' {
    $script:associationFault = ''
    $api = { param($Method, $Endpoint, $Body)
        if ($Endpoint.Contains('/jobs?')) {
            $id = if ($script:associationFault -ceq 'runner') { 8 } else { 7 }
            $count = if ($script:associationFault -ceq 'multiple') { 2 } else { 1 }
            return @{ Status = 200; Data = @{ total_count = $count; jobs = @(@{ runner_id = $id; status = 'completed'; conclusion = 'success'; id = 17 }) } }
        }
        return @{ Status = 200; Data = @{ head_sha = $(if ($script:associationFault -ceq 'head') { 'c' * 40 } else { 'b' * 40 });
            event = $(if ($script:associationFault -ceq 'event') { 'pull_request' } else { 'workflow_dispatch' });
            display_title = 'CI-PoC002 ' + ('a' * 32); run_attempt = $(if ($script:associationFault -ceq 'rerun') { 2 } else { 1 }) } }
    }
    $arguments = @{ RunId = 13; RunnerId = 7; WorkflowCommit = ('b' * 40); ComparisonId = ('a' * 32); Api = $api }
    Assert-RunnerTest ((Get-RunnerAssociatedJob @arguments).id -eq 17)
    foreach ($fault in @('head', 'event', 'rerun', 'runner', 'multiple')) {
        $script:associationFault = $fault
        Assert-RunnerThrows { Get-RunnerAssociatedJob @arguments }
    }
}

Test-RunnerCase 'no approved job expires even when a run is queued or an unassociated runner is busy' {
    Assert-RunnerTest (-not (Test-RunnerQueueExpired -ElapsedSeconds 29 -QueueSeconds 30 -ApprovedJobStarted $false))
    Assert-RunnerTest (Test-RunnerQueueExpired -ElapsedSeconds 30 -QueueSeconds 30 -ApprovedJobStarted $false)
    Assert-RunnerTest (Test-RunnerQueueExpired -ElapsedSeconds 900 -QueueSeconds 30 -ApprovedJobStarted $false)
    Assert-RunnerTest (-not (Test-RunnerQueueExpired -ElapsedSeconds 9000 -QueueSeconds 30 -ApprovedJobStarted $true))
    Assert-RunnerThrows { Test-RunnerQueueExpired -ElapsedSeconds ([double]::NaN) -QueueSeconds 30 -ApprovedJobStarted $false }
}

Test-RunnerCase 'corrupt cached runner refuses execution and preserves backing sentinels' {
    $root = Join-Path ([IO.Path]::GetTempPath()) ('runloc archive tests ' + [Guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($root)
    $pin = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'runner.json')) | ConvertFrom-Json
    $archive = Join-Path $root ('actions-runner-' + $pin.version + '.zip')
    [IO.File]::WriteAllText($archive, 'corrupt-payload')
    [IO.File]::WriteAllText((Join-Path $root 'sentinel'), 'KEEP')
    try {
        Assert-RunnerThrows { Get-RunnerPinnedArchive -BackingRoot $root }
        Assert-RunnerTest ([IO.File]::ReadAllText($archive) -ceq 'corrupt-payload')
        Assert-RunnerTest ([IO.File]::ReadAllText((Join-Path $root 'sentinel')) -ceq 'KEEP')
    }
    finally { [IO.File]::Delete($archive); [IO.File]::Delete((Join-Path $root 'sentinel')); [IO.Directory]::Delete($root, $false) }
}

Test-RunnerCase 'unique names refuse reuse before POST' {
    $script:postCount = 0
    $api = { param($Method, $Endpoint, $Body)
        if ($Method -ceq 'POST') { $script:postCount++ }
        return @{ Status = 200; Data = @{ total_count = 1; runners = @(@{ name = $runnerName; id = 7 }) } }
    }
    Assert-RunnerThrows { New-RunnerRegistration -Name $runnerName -Api $api }
    Assert-RunnerTest ($script:postCount -eq 0)
    Assert-RunnerThrows { Get-RunnerByName -Name '../not-owned' -Api $api }
}
Test-RunnerCase 'JIT registration uses only its unique label and returns capability without logging' {
    $api = { param($Method, $Endpoint, $Body)
        if ($Method -ceq 'GET') { return @{ Status = 200; Data = @{ total_count = 0; runners = @() } } }
        Assert-RunnerTest ($Body.labels.Count -eq 1 -and $Body.labels[0] -ceq $runnerName -and $Body.work_folder -ceq '_work')
        return @{ Status = 201; Data = @{ runner = @{ name = $runnerName; id = 7 }; encoded_jit_config = 'SYNTHETIC_CAPABILITY' } }
    }
    $result = New-RunnerRegistration -Name $runnerName -Api $api
    Assert-RunnerTest ($result.runner.id -eq 7 -and $result.encoded_jit_config -ceq 'SYNTHETIC_CAPABILITY')
}
Test-RunnerCase 'lost POST reconciles exact UUID and deletes its ID without a second registration' {
    $script:postCount = 0; $script:getCount = 0; $script:deleted = $false
    $api = { param($Method, $Endpoint, $Body)
        if ($Method -ceq 'POST') { $script:postCount++; throw 'SYNTHETIC_SECRET must not escape' }
        if ($Method -ceq 'DELETE') { Assert-RunnerTest ($Endpoint.EndsWith('/7')); $script:deleted = $true; return @{ Status = 204; Data = $null } }
        if ($Endpoint.Contains('?')) {
            $script:getCount++
            if ($script:getCount -eq 1) { return @{ Status = 200; Data = @{ total_count = 0; runners = @() } } }
            return @{ Status = 200; Data = @{ total_count = 1; runners = @(@{ name = $runnerName; id = 7 }) } }
        }
        if ($script:deleted) { return @{ Status = 404; Data = $null } }
        return @{ Status = 200; Data = @{ name = $runnerName; id = 7 } }
    }
    $message = ''
    try { New-RunnerRegistration -Name $runnerName -Api $api | Out-Null } catch { $message = $_.Exception.Message }
    Assert-RunnerTest ($script:postCount -eq 1 -and $script:deleted -and $message -cnotmatch 'SYNTHETIC_SECRET')
}
Test-RunnerCase 'wrong ID/name cannot delete another runner and uncertain API state never means absent' {
    $script:deleted = $false
    foreach ($status in @(200, 403, 429, 500)) {
        $api = { param($Method, $Endpoint, $Body)
            if ($Method -ceq 'DELETE') { $script:deleted = $true }
            return @{ Status = $status; Data = @{ name = 'unrelated'; id = 8 } }
        }
        Assert-RunnerThrows { Remove-RunnerRegistration -Name $runnerName -RunnerId 7 -Api $api }
    }
    Assert-RunnerTest (-not $script:deleted)
    $api = { @{ Status = 403; Data = $null } }
    Assert-RunnerThrows { Get-RunnerByName -Name $runnerName -Api $api }
}
Test-RunnerCase 'DELETE success requires an independent 404 confirmation' {
    $api = { param($Method, $Endpoint, $Body)
        if ($Method -ceq 'DELETE') { return @{ Status = 204; Data = $null } }
        return @{ Status = 200; Data = @{ id = 7; name = $runnerName } }
    }
    Assert-RunnerThrows { Remove-RunnerRegistration -Name $runnerName -RunnerId 7 -Api $api }
    $api = { @{ Status = 404; Data = $null } }
    Assert-RunnerTest (Remove-RunnerRegistration -Name $runnerName -RunnerId 7 -Api $api)
}
Test-RunnerCase 'unexpected inventory size or duplicate matching names fail closed' {
    $api = { @{ Status = 200; Data = @{ total_count = 101; runners = @() } } }
    Assert-RunnerThrows { Get-RunnerByName -Name $runnerName -Api $api }
    $api = { @{ Status = 200; Data = @{ total_count = 2; runners = @(@{ name = $runnerName }, @{ name = $runnerName }) } } }
    Assert-RunnerThrows { Get-RunnerByName -Name $runnerName -Api $api }
}
Test-RunnerCase 'JIT file vocabulary ephemeral identity and work-folder are independently enforced' {
    function New-SyntheticJit {
        param([object]$Settings, [switch]$Unexpected)
        $settingsEncoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($Settings | ConvertTo-Json -Compress)))
        $files = [ordered]@{ '.runner' = $settingsEncoded; '.credentials' = 'e30='; '.credentials_rsaparams' = 'e30=' }
        if ($Unexpected) { $files['../escape'] = 'e30=' }
        return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($files | ConvertTo-Json -Compress)))
    }
    $settings = @{ agentId = 7; agentName = $runnerName; ephemeral = $true; workFolder = '_work' }
    $good = New-SyntheticJit $settings
    $encoded = ConvertTo-RunnerPinnedJitConfig -Encoded $good -RunnerId 7 -Name $runnerName
    $files = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded)) | ConvertFrom-Json
    $observed = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($files.'.runner')) | ConvertFrom-Json
    Assert-RunnerTest ($observed.disableUpdate -eq $true -and $observed.ephemeral -eq $true)
    Assert-RunnerThrows { ConvertTo-RunnerPinnedJitConfig -Encoded $good -RunnerId 8 -Name $runnerName }
    Assert-RunnerThrows { ConvertTo-RunnerPinnedJitConfig -Encoded $good -RunnerId 7 -Name ('runloc-' + ('b' * 32)) }
    Assert-RunnerThrows { ConvertTo-RunnerPinnedJitConfig -Encoded (New-SyntheticJit $settings -Unexpected) -RunnerId 7 -Name $runnerName }
    foreach ($literal in @('True', 'true')) {
        $settings.ephemeral = $literal
        $encoded = ConvertTo-RunnerPinnedJitConfig -Encoded (New-SyntheticJit $settings) -RunnerId 7 -Name $runnerName
        $files = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded)) | ConvertFrom-Json
        $observed = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($files.'.runner')) | ConvertFrom-Json
        Assert-RunnerTest ($observed.ephemeral -is [bool] -and $observed.ephemeral -and $observed.disableUpdate -eq $true)
    }
    foreach ($invalid in @($false, 'False', 'false', '', 'yes', '1', 1, $null)) {
        $settings.ephemeral = $invalid
        Assert-RunnerThrows { ConvertTo-RunnerPinnedJitConfig -Encoded (New-SyntheticJit $settings) -RunnerId 7 -Name $runnerName }
    }
    $settings.ephemeral = $true; $settings.workFolder = '../external'
    Assert-RunnerThrows { ConvertTo-RunnerPinnedJitConfig -Encoded (New-SyntheticJit $settings) -RunnerId 7 -Name $runnerName }
}

if ($script:PilotWindows) {
    Test-RunnerCase 'nested external qualification fixtures require exact lease ownership and proven process exit' {
        Import-PilotNative
        $parent = Join-Path ([Environment]::GetFolderPath('UserProfile')) ('rt-' + [Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($parent)
        Set-PilotPrivateDirectory -Path $parent
        $lease = New-PilotLease -EvidenceParent $parent -CandidateCommit ('a' * 40) -ControllerCommit ('b' * 40) -WorkParent ([Environment]::GetFolderPath('UserProfile'))
        $outer = $null; $inner = $null
        $clock = [Diagnostics.Stopwatch]::StartNew()
        try {
            New-PilotFixture -Lease $lease
            [IO.File]::WriteAllText((Join-Path $parent 'unrelated.txt'), 'KEEP')
            $evidence = Join-Path $lease.Fixture 'runner/_work/j12345678/Evidence'
            [void][IO.Directory]::CreateDirectory($evidence)
            $outer = New-PilotLease -EvidenceParent $evidence -CandidateCommit ('a' * 40) -ControllerCommit ('b' * 40)
            $attempts = Join-Path $outer.Private 'attempts'
            [void][IO.Directory]::CreateDirectory($attempts)
            $inner = New-PilotLease -EvidenceParent $attempts -CandidateCommit ('a' * 40) -ControllerCommit ('b' * 40) -SupervisorLeaseId $outer.Id -WorkParent ([Environment]::GetFolderPath('UserProfile'))
            New-PilotFixture -Lease $inner
            [IO.File]::WriteAllText((Join-Path $inner.Fixture 'sensitive-synthetic.txt'), 'synthetic only')
            $inner.Lock.Dispose()
            Assert-RunnerThrows { Remove-RunnerNestedFixtures -Lease $lease -ExpectedJobControllerCommit ('b' * 40) -ExpectedCandidateCommit ('a' * 40) -Clock $clock -OwnedProcessesExited $false }
            Assert-RunnerTest ([IO.Directory]::Exists($inner.Fixture))
            Assert-RunnerThrows { Remove-RunnerNestedFixtures -Lease $lease -ExpectedJobControllerCommit ('c' * 40) -ExpectedCandidateCommit ('a' * 40) -Clock $clock -OwnedProcessesExited $true }
            Assert-RunnerTest ([IO.Directory]::Exists($inner.Fixture))
            Remove-RunnerNestedFixtures -Lease $lease -ExpectedJobControllerCommit ('b' * 40) -ExpectedCandidateCommit ('a' * 40) -Clock $clock -OwnedProcessesExited $true
            Assert-RunnerTest (-not [IO.Directory]::Exists($inner.Fixture))
            Assert-RunnerTest ([IO.File]::ReadAllText((Join-Path $parent 'unrelated.txt')) -ceq 'KEEP')
            $outer.Lock.Dispose()
            Remove-PilotFixture -Lease $lease -Clock $clock -DeadlineSeconds 60 -OwnedProcessesExited $true
        }
        finally {
            if ($null -ne $inner) { $inner.Lock.Dispose() }
            if ($null -ne $outer) { $outer.Lock.Dispose() }
            $lease.Lock.Dispose()
        }
    }
    Test-RunnerCase 'native capability remains out of argv and host credentials stay out of child environment' {
        Import-PilotNative
        $parent = Join-Path ([IO.Path]::GetTempPath()) ('runloc runner tests ' + [Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($parent)
        Set-PilotPrivateDirectory -Path $parent
        $lease = New-PilotLease -EvidenceParent $parent -CandidateCommit ('a' * 40) -ControllerCommit ('b' * 40)
        $job = $null; $old = $env:GH_TOKEN
        try {
            New-PilotFixture -Lease $lease
            $code = 'using System; public class RunnerFixture { public static void Main(string[] args) { if (Environment.GetEnvironmentVariable("ACTIONS_RUNNER_INPUT_JITCONFIG") != "synthetic-jit" || Environment.GetEnvironmentVariable("GH_TOKEN") != null || string.Join(" ",args).Contains("synthetic")) Environment.Exit(9); Console.WriteLine("ENV_OK"); } }'
            $exe = Join-Path $lease.Fixture 'Runner.Listener.exe'
            $codePath = Join-Path $lease.Fixture 'RunnerFixture.cs'
            [IO.File]::WriteAllText($codePath, $code)
            & (Join-Path $env:SystemRoot 'Microsoft.NET/Framework64/v4.0.30319/csc.exe') /nologo ('/out:' + $exe) $codePath
            if ($LASTEXITCODE -ne 0) { throw 'runner-fixture-compile-failed' }
            $env:GH_TOKEN = 'synthetic-admin-secret'
            $log = Join-Path $lease.Private 'native.log'
            $job = New-Object RunlocPoc.OwnedProcess($exe, [string[]]@('run', '--once'), $lease.Fixture, $lease.Fixture, $log, [long]1048576, 'synthetic-jit')
            $clock = [Diagnostics.Stopwatch]::StartNew()
            while (-not $job.HasExited -and $clock.Elapsed.TotalSeconds -lt 10) { Start-Sleep -Milliseconds 50 }
            Assert-RunnerTest ($job.HasExited -and $job.ExitCode -eq 0 -and $job.ActiveProcesses -eq 0 -and $job.FinishOutput(2000))
            $lines = @($job.Drain())
            Assert-RunnerTest (@($lines | Where-Object { $_.Text -ceq 'ENV_OK' }).Count -eq 1)
            $job.Dispose(); $job = $null
            Assert-RunnerTest (-not [IO.File]::ReadAllText($log).Contains('synthetic'))
            Remove-PilotFixture -Lease $lease -Clock $clock -DeadlineSeconds 20 -OwnedProcessesExited $true
            Assert-RunnerTest ([IO.Directory]::Exists($parent) -and -not [IO.Directory]::Exists($lease.Fixture))
        }
        finally {
            $env:GH_TOKEN = $old
            if ($null -ne $job) { $job.Dispose() }
            $lease.Lock.Dispose()
            # This bounded test directory has no guest disks or secrets. Keep
            # normal ownership-checked fixture disposal above as the assertion.
        }
    }
}
else { Write-Host 'SKIP native Windows runner environment group' }
Write-Host ('Runner groups passed: ' + $passed)
