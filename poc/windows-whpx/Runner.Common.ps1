#requires -Version 5.1
. (Join-Path $PSScriptRoot 'Pilot.Common.ps1')

function Test-RunnerQueueExpired {
    param([double]$ElapsedSeconds, [ValidateRange(1, 1800)][int]$QueueSeconds, [bool]$ApprovedJobStarted)
    Assert-PilotTelemetryNumber -Value $ElapsedSeconds
    return -not $ApprovedJobStarted -and $ElapsedSeconds -ge $QueueSeconds
}

function Assert-RunnerRouting {
    param([object]$Runner, [string]$Name)
    $labels = @($Runner.labels)
    if ($Runner.name -cne $Name -or $labels.Count -ne 1 -or $labels[0].name -cne $Name) { throw 'runner-routing-not-isolated' }
}

function Test-RunnerFinalOutcome {
    param([bool]$JobPassed, [string]$Reason, [bool]$Exited, [object]$ActiveProcesses,
        [bool]$Forced, [bool]$RemoteAbsent, [bool]$FixtureRemoved, [bool]$BackingIntact,
        [bool]$SentinelIntact, [bool]$SourceIntact, [bool]$WorkflowCleanupConfirmed)
    return $JobPassed -and $Reason -ceq 'job-completed' -and $Exited -and
        $null -ne $ActiveProcesses -and $ActiveProcesses -eq 0 -and -not $Forced -and
        $RemoteAbsent -and $FixtureRemoved -and $BackingIntact -and $SentinelIntact -and $SourceIntact -and $WorkflowCleanupConfirmed
}

function Get-RunnerAssociatedJob {
    param([long]$RunId, [long]$RunnerId, [string]$WorkflowCommit, [string]$ComparisonId,
        [scriptblock]$Api = ${function:Invoke-RunnerApi})
    $run = & $Api -Method GET -Endpoint ('repos/techrote/ezvm/actions/runs/' + $RunId)
    if ($run.Status -ne 200 -or $run.Data.head_sha -cne $WorkflowCommit -or $run.Data.event -cne 'workflow_dispatch' -or
        $run.Data.display_title -cne ('CI-PoC002 ' + $ComparisonId) -or $run.Data.run_attempt -ne 1) { throw 'workflow-run-identity-mismatch' }
    $jobs = & $Api -Method GET -Endpoint ('repos/techrote/ezvm/actions/runs/' + $RunId + '/jobs?per_page=100')
    if ($jobs.Status -ne 200 -or $jobs.Data.total_count -gt 1) { throw 'job-association-unknown-or-multiple' }
    $assigned = @($jobs.Data.jobs | Where-Object { $_.runner_id -gt 0 })
    if ($assigned.Count -gt 1 -or ($assigned.Count -eq 1 -and $assigned[0].runner_id -ne $RunnerId)) { throw 'job-runner-identity-mismatch' }
    if ($assigned.Count -eq 1) { return $assigned[0] }
    return $null
}

function Invoke-RunnerApi {
    param([ValidateSet('GET', 'POST', 'DELETE')][string]$Method = 'GET',
        [Parameter(Mandatory = $true)][string]$Endpoint, [object]$Body = $null)
    if ($Endpoint -cnotmatch '^repos/techrote/ezvm/(actions/|contents/|git/|commits/)') { throw 'api-endpoint-not-approved' }
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = (Get-Command gh.exe -CommandType Application -ErrorAction Stop).Source
    $arguments = @('api', '--include', '--method', $Method, '-H', 'Accept: application/vnd.github+json', '-H', 'X-GitHub-Api-Version: 2026-03-10', $Endpoint)
    if ($null -ne $Body) { $arguments += @('--input', '-') }
    Import-PilotNative
    $start.Arguments = (@($arguments | ForEach-Object { [RunlocPoc.OwnedProcess]::QuoteArgument($_) }) -join ' ')
    $start.UseShellExecute = $false; $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true; $start.RedirectStandardInput = $true
    $process = New-Object Diagnostics.Process; $process.StartInfo = $start
    try {
        if (-not $process.Start()) { throw 'api-process-start-failed' }
        $output = $process.StandardOutput.ReadToEndAsync(); $errors = $process.StandardError.ReadToEndAsync()
        if ($null -ne $Body) { $process.StandardInput.Write(($Body | ConvertTo-Json -Depth 12 -Compress)) }
        $process.StandardInput.Close()
        if (-not $process.WaitForExit(30000)) { $process.Kill(); throw 'api-response-unknown' }
        if (-not $output.Wait(2000) -or -not $errors.Wait(2000)) { throw 'api-response-unknown' }
        $text = $output.Result
        if ($text.Length -gt 4194304 -or $text -cnotmatch '^HTTP/[0-9.]+ ([0-9]{3})') { throw 'api-response-unknown' }
        $status = [int]$Matches[1]
        $parts = $text -split '\r?\n\r?\n', 2
        $data = $null
        if ($parts.Count -eq 2 -and $parts[1].Trim()) { $data = $parts[1] | ConvertFrom-Json -ErrorAction Stop }
        # Never forward gh stderr or response bodies into exceptions/logs.
        return [pscustomobject]@{ Status = $status; Data = $data }
    }
    catch { throw 'github-api-failed-or-unknown' }
    finally { $process.Dispose() }
}

function Get-RunnerByName {
    param([Parameter(Mandatory = $true)][ValidatePattern('^runloc-[a-f0-9]{32}$')][string]$Name,
        [scriptblock]$Api = ${function:Invoke-RunnerApi})
    $response = & $Api -Method GET -Endpoint ('repos/techrote/ezvm/actions/runners?per_page=100&name=' + $Name)
    if ($response.Status -ne 200 -or $response.Data.total_count -gt 100) { throw 'runner-inventory-unknown' }
    $matches = @($response.Data.runners | Where-Object { $_.name -ceq $Name })
    if ($matches.Count -gt 1) { throw 'runner-name-ambiguous' }
    if ($matches.Count -eq 1) { return $matches[0] }
    return $null
}

function Remove-RunnerRegistration {
    param([Parameter(Mandatory = $true)][string]$Name, [long]$RunnerId,
        [scriptblock]$Api = ${function:Invoke-RunnerApi})
    if ($RunnerId -le 0) { throw 'runner-id-required' }
    $endpoint = 'repos/techrote/ezvm/actions/runners/' + $RunnerId
    $observed = & $Api -Method GET -Endpoint $endpoint
    if ($observed.Status -eq 404) { return $true }
    if ($observed.Status -ne 200 -or $observed.Data.id -ne $RunnerId -or $observed.Data.name -cne $Name) { throw 'runner-ownership-unknown' }
    $removed = & $Api -Method DELETE -Endpoint $endpoint
    if ($removed.Status -ne 204 -and $removed.Status -ne 404) { throw 'runner-removal-unconfirmed' }
    $after = & $Api -Method GET -Endpoint $endpoint
    if ($after.Status -ne 404) { throw 'runner-removal-unconfirmed' }
    return $true
}

function New-RunnerRegistration {
    param([Parameter(Mandatory = $true)][ValidatePattern('^runloc-[a-f0-9]{32}$')][string]$Name,
        [scriptblock]$Api = ${function:Invoke-RunnerApi})
    if ($null -ne (Get-RunnerByName -Name $Name -Api $Api)) { throw 'runner-name-already-used' }
    try {
        $response = & $Api -Method POST -Endpoint 'repos/techrote/ezvm/actions/runners/generate-jitconfig' -Body @{
            name = $Name; runner_group_id = 1; labels = @($Name); work_folder = '_work' }
        if ($response.Status -ne 201 -or $response.Data.runner.name -cne $Name -or $response.Data.runner.id -le 0 -or
            $response.Data.encoded_jit_config -isnot [string]) { throw 'runner-registration-unknown' }
        return $response.Data
    }
    catch {
        # A lost POST response never authorizes another POST or capability reuse.
        $found = Get-RunnerByName -Name $Name -Api $Api
        if ($null -ne $found) { $null = Remove-RunnerRegistration -Name $Name -RunnerId $found.id -Api $Api }
        throw 'runner-registration-failed-reconcile-before-new-attempt'
    }
}

function ConvertTo-RunnerPinnedJitConfig {
    param([Parameter(Mandatory = $true)][string]$Encoded, [long]$RunnerId, [string]$Name)
    try {
        if ($Encoded.Length -gt 262144) { throw 'oversize' }
        $files = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Encoded)) | ConvertFrom-Json
        $allowed = @('.runner', '.credentials', '.credentials_rsaparams')
        foreach ($property in $files.PSObject.Properties) {
            if ($allowed -cnotcontains $property.Name -or $property.Value -isnot [string]) { throw 'unknown-file' }
        }
        foreach ($required in $allowed) { if ($null -eq $files.PSObject.Properties[$required]) { throw 'missing-file' } }
        $settings = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($files.'.runner')) | ConvertFrom-Json
        if ($settings.agentId -ne $RunnerId -or $settings.agentName -cne $Name -or $settings.ephemeral -isnot [bool] -or
            -not $settings.ephemeral -or $settings.workFolder -cne '_work') { throw 'settings-mismatch' }
        # Freeze the verified runner version. A later version needs new review,
        # never an automatic executable replacement during this registration.
        $settings | Add-Member -MemberType NoteProperty -Name disableUpdate -Value $true -Force
        $files.'.runner' = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($settings | ConvertTo-Json -Depth 12 -Compress)))
        return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($files | ConvertTo-Json -Depth 12 -Compress)))
    }
    catch { throw 'jit-capability-invalid' }
}

function Get-RunnerPinnedArchive {
    param([string]$BackingRoot)
    $root = Assert-PilotPath -Path $BackingRoot
    $pin = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'runner.json')) | ConvertFrom-Json
    $archive = Join-Path $root ('actions-runner-' + $pin.version + '.zip')
    if (-not [IO.File]::Exists($archive)) {
        $temporary = Join-Path $root ('download-' + [Guid]::NewGuid().ToString('N') + '.tmp')
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -UseBasicParsing -Uri $pin.url -OutFile $temporary -TimeoutSec 180
            $null = Assert-PilotPath -Path $temporary -File
            if ((Get-Item -LiteralPath $temporary).Length -ne $pin.sizeBytes -or (Get-PilotDigest -Path $temporary) -cne $pin.sha256) { throw 'runner-archive-pin-mismatch' }
            [IO.File]::Move($temporary, $archive)
        }
        finally { if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) } }
    }
    $null = Assert-PilotPath -Path $archive -File
    if ((Get-Item -LiteralPath $archive).Length -ne $pin.sizeBytes -or (Get-PilotDigest -Path $archive) -cne $pin.sha256) { throw 'runner-archive-pin-mismatch' }
    return $archive
}

function Remove-RunnerNestedFixtures {
    param([object]$Lease, [string]$ExpectedJobControllerCommit, [string]$ExpectedCandidateCommit,
        [Diagnostics.Stopwatch]$Clock, [Parameter(Mandatory = $true)][bool]$OwnedProcessesExited)
    Assert-PilotLease -Lease $Lease
    if (-not $OwnedProcessesExited) { throw 'runner-process-state-unresolved' }
    if ($ExpectedJobControllerCommit -cnotmatch '^[a-f0-9]{40}$') { throw 'job-controller-pin-required' }
    $temporary = Join-Path $Lease.Fixture 'runner/_work'
    $results = @()
    if (-not [IO.Directory]::Exists($temporary)) { return }
    $null = Assert-PilotPath -Path $temporary
    $jobRoots = @(Get-ChildItem -LiteralPath $temporary -Directory | Where-Object { $_.Name -cmatch '^j[a-f0-9]{8}$' })
    if ($jobRoots.Count -gt 4) { throw 'job-fixture-count-invalid' }
    foreach ($jobRoot in $jobRoots) {
        $null = Assert-PilotPath -Path $jobRoot.FullName
        $evidence = Join-Path $jobRoot.FullName 'Evidence'
        if (-not [IO.Directory]::Exists($evidence)) { continue }
        $null = Assert-PilotPath -Path $evidence
        foreach ($outer in @(Get-ChildItem -LiteralPath $evidence -Directory)) {
            if ($outer.Name -cnotmatch '^runloc-whpx-([a-f0-9]{32})$') { throw 'nested-evidence-name-invalid' }
            $outerId = $Matches[1]
            $null = Assert-PilotPath -Path $outer.FullName
            $savedOuter = Join-Path $Lease.Private ('qualification-evidence/' + $outerId)
            [void][IO.Directory]::CreateDirectory($savedOuter)
            foreach ($file in @('supervisor-started.json', 'supervisor-receipt.json', 'supervisor-receipt-digest.json')) {
                $path = Join-Path $outer.FullName $file
                if ([IO.File]::Exists($path)) { $null = Assert-PilotPath -Path $path -File; [IO.File]::Copy($path, (Join-Path $savedOuter $file), $false) }
            }
            $attempts = Join-Path $outer.FullName 'private/attempts'
            if (-not [IO.Directory]::Exists($attempts)) { continue }
            $null = Assert-PilotPath -Path $attempts
            foreach ($inner in @(Get-ChildItem -LiteralPath $attempts -Directory)) {
                if ($inner.Name -cnotmatch '^runloc-whpx-([a-f0-9]{32})$') { throw 'nested-attempt-name-invalid' }
                $innerId = $Matches[1]
                $innerRoot = Assert-PilotPath -Path $inner.FullName
                $ownerPath = Assert-PilotPath -Path (Join-Path $innerRoot 'lease.json') -File
                $owner = [IO.File]::ReadAllText($ownerPath) | ConvertFrom-Json
                if ($owner.root -cne $innerRoot -or $owner.leaseId -cne $innerId -or $owner.supervisorLeaseId -cne $outerId -or
                    $owner.candidateCommit -cne $ExpectedCandidateCommit -or $owner.controllerCommit -cne $ExpectedJobControllerCommit -or
                    $owner.workParent -cne [Environment]::GetFolderPath('UserProfile')) { throw 'nested-lease-not-owned' }
                $lock = [IO.File]::Open((Join-Path $innerRoot 'active.lock'), [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
                try {
                    $creation = Join-Path $innerRoot 'fixture-created.json'
                    $created = [IO.File]::Exists($creation)
                    $nested = [pscustomobject]@{ Id = $innerId; Root = $innerRoot; Private = (Join-Path $innerRoot 'private');
                        Fixture = $owner.fixture; WorkParent = $owner.workParent; Lock = $lock; OwnerDigest = (Get-PilotDigest -Path $ownerPath);
                        CandidateCommit = $owner.candidateCommit; ControllerCommit = $owner.controllerCommit;
                        FixtureCreated = $created; FixtureCreationDigest = $(if ($created) { Get-PilotDigest -Path $creation } else { '' }) }
                    $saved = Join-Path $savedOuter $innerId
                    [void][IO.Directory]::CreateDirectory($saved)
                    foreach ($file in @('receipt.json', 'receipt-digest.json', 'telemetry-events.json')) {
                        $path = Join-Path $innerRoot $file
                        if ([IO.File]::Exists($path)) { $null = Assert-PilotPath -Path $path -File; [IO.File]::Copy($path, (Join-Path $saved $file), $false) }
                    }
                    # These two files remain private, including for failed or
                    # interrupted attempts. Never upload the enclosing folder.
                    foreach ($file in @('telemetry.jsonl', 'qualification.log')) {
                        $path = Join-Path $nested.Private $file
                        if ([IO.File]::Exists($path)) {
                            $null = Assert-PilotPath -Path $path -File
                            if ((Get-Item -LiteralPath $path).Length -gt 16MB) { throw 'nested-diagnostic-size-limit' }
                            [IO.File]::Copy($path, (Join-Path $saved ('private-' + $file)), $false)
                        }
                    }
                    Remove-PilotFixture -Lease $nested -Clock $Clock -DeadlineSeconds ($Clock.Elapsed.TotalSeconds + 180) -OwnedProcessesExited $true
                    $results += @{ leaseId = $innerId; fixtureRemoved = -not [IO.Directory]::Exists($nested.Fixture); activeProcesses = 0;
                        containmentProof = 'empty-outer-native-job-with-no-breakaway' }
                }
                finally { $lock.Dispose() }
            }
        }
    }
    Write-PilotNewJson -Path (Join-Path $Lease.Root 'nested-cleanup.json') -Value @{ schemaVersion = 1; attempts = $results }
}
