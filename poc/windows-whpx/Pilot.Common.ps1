#requires -Version 5.1
Set-StrictMode -Version Latest
$script:PilotWindows = [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
$script:PilotMarkers = @(
    'EZVM012_REAL_FRESH_ROOT_DOCTOR', 'EZVM012_REAL_BOOTSTRAP_DOCTOR',
    'EZVM010_REAL_TINY_RESET_FRESH_STATEFUL_INDEPENDENCE', 'EZVM010_REAL_SENSITIVE_BASELINE_RESET_AND_FRESH',
    'EZVM010_REAL_STANDALONE_EXPORT_IMPORT', 'EZVM010_REAL_UNSAFE_IMPORT_REFUSAL',
    'EZVM010_REAL_FAILED_EXPORT_PRESERVES_DATA', 'EZVM012_REAL_TWO_CONCURRENT_READY_GUESTS',
    'EZVM011_REAL_SCP_ROUNDTRIP_AND_FAILED_DESTINATION_PRESERVATION',
    'EZVM011_REAL_RUNNING_DIAGNOSIS_AND_RUNTIME_TRANSFER_REFUSAL', 'EZVM012_REAL_STOP_RESTART_PERSISTENCE',
    'EZVM010_REAL_RUNNING_OPERATIONS_REFUSE', 'EZVM012_REAL_FRESH_CLONE_PRISTINE_READY',
    'EZVM010_REAL_RESET_PRISTINE_READY', 'EZVM010_REAL_STATEFUL_NEW_IDENTITY_AND_CONTENT',
    'EZVM010_REAL_IMPORTED_NEW_IDENTITY_AND_CONTENT', 'EZVM012_REAL_RELOCATED_DOCTOR',
    'EZVM010_REAL_COLD_RELOCATION_READY', 'EZVM010_REAL_RELATIVE_BACKING_AND_RUNTIME_REGENERATION',
    'EZVM010_REAL_GRACEFUL_STOP', 'EZVM011_REAL_COMPLETE_SECURITY_AND_PORTABILITY',
    'EZVM012_REAL_RELOCATED_DOCTOR_AND_RESTART', 'EZVM012_REAL_COMPLETE_END_TO_END', 'EZVM010_WHPX_EXECUTION'
)
$script:PilotSteps = @('tiny_real_images', 'prepare_real_guest', 'base_build_started', 'base_build_completed',
    'guest_start', 'guest_ready', 'guest_start_failed', 'real_host_transfer_and_diagnosis',
    'copy_export_import', 'reset_source_ready', 'stateful_clone_ready', 'imported_guest_ready',
    'complete_cold_relocation', 'source_root_unavailable', 'source_root_restored')

function Import-PilotNative {
    if (-not ('RunlocPoc.OwnedProcess' -as [type])) {
        Add-Type -Path (Join-Path $PSScriptRoot 'OwnedProcess.cs') -ErrorAction Stop
    }
}

function Get-PilotDigest {
    param([Parameter(Mandatory = $true)][string]$Path, [switch]$NormalizeText)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        if ($NormalizeText) {
            $bytes = [Text.Encoding]::UTF8.GetBytes(([IO.File]::ReadAllText($Path).Replace("`r`n", "`n")))
            $digest = $algorithm.ComputeHash($bytes)
        }
        else {
            $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
            try { $digest = $algorithm.ComputeHash($stream) } finally { $stream.Dispose() }
        }
        return ([BitConverter]::ToString($digest)).Replace('-', '').ToLowerInvariant()
    }
    finally { $algorithm.Dispose() }
}

function Get-PilotBlobId {
    param([byte[]]$Bytes)
    $algorithm = [Security.Cryptography.SHA1]::Create()
    try {
        $header = [Text.Encoding]::ASCII.GetBytes('blob ' + $Bytes.Length + [char]0)
        $null = $algorithm.TransformBlock($header, 0, $header.Length, $null, 0)
        $null = $algorithm.TransformFinalBlock($Bytes, 0, $Bytes.Length)
        return ([BitConverter]::ToString($algorithm.Hash)).Replace('-', '').ToLowerInvariant()
    }
    finally { $algorithm.Dispose() }
}

function Assert-PilotPath {
    param([Parameter(Mandatory = $true)][string]$Path, [switch]$AllowMissing, [switch]$File, [switch]$AllowHardlink)
    if (-not [IO.Path]::IsPathRooted($Path)) { throw 'path-not-absolute' }
    if ($script:PilotWindows -and ($Path -notmatch '^[A-Za-z]:[\\/]' -or $Path.Substring(2).Contains(':'))) {
        throw 'path-not-local-volume'
    }
    $full = [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $volume = [IO.Path]::GetPathRoot($Path)
    if ($full.Length -lt $volume.Length) { $full = $volume }
    $cursor = $full
    while ($cursor) {
        # GetAttributes also sees a dangling reparse point; Test-Path alone does not.
        try { $attributes = [IO.File]::GetAttributes($cursor) }
        catch [IO.FileNotFoundException] { $attributes = $null }
        catch [IO.DirectoryNotFoundException] { $attributes = $null }
        if ($null -ne $attributes -and ($attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'path-reparse-point' }
        if ($cursor -ceq $full -and $null -eq $attributes -and -not $AllowMissing) { throw 'path-missing' }
        $parent = [IO.Path]::GetDirectoryName($cursor)
        if (-not $parent -or $parent -ceq $cursor) { break }
        $cursor = $parent
    }
    if ($File) {
        if (-not [IO.File]::Exists($full)) { throw 'file-missing' }
        if ($script:PilotWindows -and -not $AllowHardlink) {
            Import-PilotNative
            if ([RunlocPoc.OwnedProcess]::FileLinkCount($full) -ne 1) { throw 'file-hardlink' }
        }
        elseif (-not $script:PilotWindows -and -not $AllowHardlink -and (Get-Item -LiteralPath $full -Force).LinkType -eq 'HardLink') { throw 'file-hardlink' }
    }
    return $full
}

function Test-PilotDescendant {
    param([string]$Path, [string]$Root)
    $parent = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $child = [IO.Path]::GetFullPath($Path)
    $comparison = if ($script:PilotWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    return $child.StartsWith($parent + [IO.Path]::DirectorySeparatorChar, $comparison)
}

function Assert-PilotPowerShellInvocation {
    param([object]$Value)
    # The wire format is data only. Parameter names are never re-parsed as
    # command text, and arbitrary serialized object types are not accepted.
    if ($Value -isnot [hashtable] -or $Value.PSBase.Count -ne 4) { throw 'powershell-invocation-schema' }
    foreach ($key in $Value.PSBase.Keys) {
        if ($key -isnot [string] -or @('schemaVersion', 'targetScript', 'parameters', 'arguments') -cnotcontains $key) { throw 'powershell-invocation-schema' }
    }
    if ($Value.schemaVersion -isnot [int] -or $Value.schemaVersion -ne 1 -or
        $Value.targetScript -isnot [string] -or $Value.targetScript.Length -gt 4096 -or
        $Value.targetScript.IndexOf([char]0) -ge 0 -or
        -not [string]::Equals([IO.Path]::GetExtension($Value.targetScript), '.ps1', [StringComparison]::OrdinalIgnoreCase)) { throw 'powershell-invocation-schema' }
    if ($Value.parameters -isnot [hashtable] -or $Value.parameters.PSBase.Count -gt 32 -or
        ($Value.arguments -isnot [array] -and $Value.arguments -isnot [Collections.ArrayList]) -or
        $Value.arguments.Count -gt 32) { throw 'powershell-invocation-schema' }
    $parameters = @{}
    foreach ($name in $Value.parameters.PSBase.Keys) {
        if ($name -isnot [string] -or $name -cnotmatch '^[A-Za-z][A-Za-z0-9_]{0,63}$') { throw 'powershell-parameter-name' }
        if ($parameters.ContainsKey($name)) { throw 'powershell-parameter-duplicate' }
        $argument = $Value.parameters[$name]
        if ($argument -isnot [string] -and $argument -isnot [bool] -and $argument -isnot [int] -and $argument -isnot [long]) { throw 'powershell-parameter-type' }
        if ($argument -is [string] -and ($argument.Length -gt 8192 -or $argument.IndexOf([char]0) -ge 0)) { throw 'powershell-argument-size' }
        $parameters[$name] = $argument
    }
    $arguments = New-Object 'System.Collections.Generic.List[string]'
    foreach ($argument in $Value.arguments) {
        if ($argument -isnot [string]) { throw 'powershell-positional-type' }
        if ($argument.Length -gt 8192 -or $argument.IndexOf([char]0) -ge 0) { throw 'powershell-argument-size' }
        $arguments.Add($argument)
    }
    $target = Assert-PilotPath -Path $Value.targetScript -File
    return [pscustomobject]@{ TargetScript = $target; NamedParameters = $parameters; PositionalArguments = $arguments.ToArray() }
}

function Get-PilotPowerShellArguments {
    param([Parameter(Mandatory = $true)][string]$TargetScript, [hashtable]$NamedParameters = @{},
        [AllowEmptyCollection()][object[]]$PositionalArguments = @())
    $invocation = Assert-PilotPowerShellInvocation -Value @{ schemaVersion = 1; targetScript = $TargetScript;
        parameters = $NamedParameters; arguments = $PositionalArguments }
    $envelope = @{ schemaVersion = 1; targetScript = $invocation.TargetScript;
        parameters = $invocation.NamedParameters; arguments = [string[]]$invocation.PositionalArguments }
    $xml = [Management.Automation.PSSerializer]::Serialize($envelope, 6)
    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($xml))
    if ($encoded.Length -gt 24000) { throw 'powershell-invocation-too-large' }
    $entry = Assert-PilotPath -Path ([IO.Path]::Combine($PSScriptRoot, 'Pilot.PowerShellEntry.ps1')) -File
    $arguments = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $entry, '-InvocationBase64', $encoded)
    # Reserve 4096 characters for the executable plus quoting below Windows'
    # 32767-character native command-line limit. The wire is never a shell string.
    Import-PilotNative
    $characters = 4096
    foreach ($argument in $arguments) { $characters += [RunlocPoc.OwnedProcess]::QuoteArgument($argument).Length + 1 }
    if ($characters -ge 32767) { throw 'powershell-invocation-too-large' }
    return $arguments
}

function Read-PilotPowerShellInvocation {
    param([string]$InvocationBase64)
    if ([string]::IsNullOrEmpty($InvocationBase64) -or $InvocationBase64.Length -gt 24000 -or
        $InvocationBase64 -cnotmatch '^[A-Za-z0-9+/]+={0,2}$') { throw 'powershell-invocation-encoding' }
    try {
        $bytes = [Convert]::FromBase64String($InvocationBase64)
        $encoding = New-Object Text.UTF8Encoding($false, $true)
        $xml = $encoding.GetString($bytes)
        # Validate a bounded XML document with no external entity resolution
        # before the Core serializer consumes the primitive invocation envelope.
        $settings = New-Object Xml.XmlReaderSettings
        $settings.DtdProcessing = [Xml.DtdProcessing]::Prohibit
        $settings.XmlResolver = $null
        $settings.MaxCharactersInDocument = 18000
        $inputText = New-Object IO.StringReader($xml)
        $reader = [Xml.XmlReader]::Create($inputText, $settings)
        try { while ($reader.Read()) { } } finally { $reader.Dispose(); $inputText.Dispose() }
        $value = [Management.Automation.PSSerializer]::Deserialize($xml)
    }
    catch { throw 'powershell-invocation-encoding' }
    return Assert-PilotPowerShellInvocation -Value $value
}

function Get-PilotWorkPlan {
    param([string]$WorkParent, [ValidatePattern('^[a-f0-9]{32}$')][string]$LeaseId)
    $parent = Assert-PilotPath -Path $WorkParent
    if (-not [IO.Directory]::Exists($parent)) { throw 'work-parent-not-directory' }
    # Encode all 128 lease bits in a filename-safe 22-character token. Keep the
    # full hex ID in the lease and refuse any existing mapped directory.
    $token = [Convert]::ToBase64String(([Guid]::ParseExact($LeaseId, 'N')).ToByteArray()).TrimEnd([char[]]@('='))
    $fixture = Join-Path $parent ('q' + $token.Replace('+', '-').Replace('/', '_'))
    # Measured pinned QEMU installer maximum member is 87 characters; its
    # original root-A staging prefix makes 215 below the exact TEMP fixture.
    # This also covers relocation, base IDs, snapshot and atomic JSON paths.
    # Audit: docs/fast-track/evidence/windows-path-budget.json. Candidate review
    # must retain its measured source/archive pins or repeat this path audit.
    # Keep the native/Framework path limit independent of host long-path policy.
    $relativeReserve = 215; $maximumPath = 259; $directoryReserve = 173; $maximumDirectory = 247
    if ($fixture.Length + $relativeReserve -gt $maximumPath -or
        $fixture.Length + $directoryReserve -gt $maximumDirectory) { throw 'work-path-budget-exceeded' }
    $null = Assert-PilotPath -Path $fixture -AllowMissing
    return [pscustomobject]@{ Parent = $parent; Fixture = $fixture; Budget = [ordered]@{
        profile = 'ezvm-pr46-full-release-v1'; fixtureCharacters = $fixture.Length;
        relativeReserveCharacters = $relativeReserve; maximumPathCharacters = $maximumPath;
        plannedMaximumCharacters = $fixture.Length + $relativeReserve;
        relativeDirectoryReserveCharacters = $directoryReserve; maximumDirectoryCharacters = $maximumDirectory;
        plannedMaximumDirectoryCharacters = $fixture.Length + $directoryReserve } }
}

function Assert-PilotFixtureSeparation {
    param([string]$Fixture, [string[]]$ProtectedRoots)
    foreach ($root in $ProtectedRoots) {
        if ([IO.Path]::GetFullPath($Fixture) -ieq [IO.Path]::GetFullPath($root) -or
            (Test-PilotDescendant -Path $Fixture -Root $root) -or
            (Test-PilotDescendant -Path $root -Root $Fixture)) { throw 'fixture-and-protected-root-overlap' }
    }
}

function Assert-PilotMetadataBudget {
    param([string]$EvidenceParent)
    # Outer lease, private/attempts, inner lease and the preflight compiler's
    # temporary filenames must fit before a controller or ACL probe is launched.
    if ($EvidenceParent.Length + 160 -gt 259) { throw 'evidence-path-budget-exceeded' }
}

function Assert-PilotRecordedWorkBudget {
    param([object]$Budget, [int]$ExpectedFixtureCharacters = -1)
    if ($Budget.profile -isnot [string] -or $Budget.profile -cne 'ezvm-pr46-full-release-v1') { throw 'work-path-budget-invalid' }
    foreach ($field in @('fixtureCharacters', 'relativeReserveCharacters', 'maximumPathCharacters', 'plannedMaximumCharacters',
            'relativeDirectoryReserveCharacters', 'maximumDirectoryCharacters', 'plannedMaximumDirectoryCharacters')) {
        if ($Budget.$field -isnot [int] -and $Budget.$field -isnot [long]) { throw 'work-path-budget-type' }
    }
    if ($Budget.fixtureCharacters -lt 24 -or $Budget.fixtureCharacters -gt 44 -or
        ($ExpectedFixtureCharacters -ge 0 -and $Budget.fixtureCharacters -ne $ExpectedFixtureCharacters) -or
        $Budget.relativeReserveCharacters -ne 215 -or $Budget.maximumPathCharacters -ne 259 -or
        $Budget.plannedMaximumCharacters -ne ($Budget.fixtureCharacters + 215) -or $Budget.plannedMaximumCharacters -gt 259 -or
        $Budget.relativeDirectoryReserveCharacters -ne 173 -or $Budget.maximumDirectoryCharacters -ne 247 -or
        $Budget.plannedMaximumDirectoryCharacters -ne ($Budget.fixtureCharacters + 173) -or $Budget.plannedMaximumDirectoryCharacters -gt 247) { throw 'work-path-budget-invalid' }
}

function Assert-PilotDeadline {
    param([Diagnostics.Stopwatch]$Clock, [double]$DeadlineSeconds)
    if ($Clock.Elapsed.TotalSeconds -ge $DeadlineSeconds) { throw 'deadline-exceeded' }
}

function Invoke-PilotGit {
    param([string]$Root, [string[]]$Arguments, [Diagnostics.Stopwatch]$Clock = $null, [double]$DeadlineSeconds = 0)
    if ($null -ne $Clock) { Assert-PilotDeadline -Clock $Clock -DeadlineSeconds $DeadlineSeconds }
    Import-PilotNative # QuoteArgument is platform-independent; interop loads only when invoked.
    $git = @(Get-Command git -CommandType Application -ErrorAction Stop)[0].Source
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $git
    $parts = @('-c', 'core.fsmonitor=false', '-c', 'core.untrackedCache=false', '-C', $Root) + $Arguments
    $start.Arguments = (@($parts | ForEach-Object { [RunlocPoc.OwnedProcess]::QuoteArgument([string]$_) }) -join ' ')
    $start.UseShellExecute = $false; $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
    $start.EnvironmentVariables['GIT_OPTIONAL_LOCKS'] = '0'
    $start.EnvironmentVariables['GIT_NO_REPLACE_OBJECTS'] = '1'
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $start
    try {
        if (-not $process.Start()) { throw 'git-start-failed' }
        # Retain the native process handle immediately; cleanup never selects a numeric PID.
        $null = $process.Handle
        $stdout = $process.StandardOutput.ReadToEndAsync(); $stderr = $process.StandardError.ReadToEndAsync()
        $timeout = 15000
        if ($null -ne $Clock) { $timeout = [int][Math]::Max(1.0, [Math]::Min([double]$timeout, ($DeadlineSeconds - $Clock.Elapsed.TotalSeconds) * 1000)) }
        if (-not $process.WaitForExit($timeout)) { $process.Kill(); throw 'git-timeout' }
        if (-not $stdout.Wait(1000) -or -not $stderr.Wait(1000)) { throw 'git-output-timeout' }
        if ($process.ExitCode -ne 0) { throw 'git-command-failed' }
        return $stdout.Result.TrimEnd("`r", "`n")
    }
    finally { $process.Dispose() }
}

function Get-PilotSourceIdentity {
    param([string]$Root, [string]$Repository, [string]$ExpectedCommit, [string]$ExpectedTree = '', [object[]]$Pins = @(),
        [Diagnostics.Stopwatch]$Clock = $null, [double]$DeadlineSeconds = 0)
    if ($ExpectedCommit -cnotmatch '^[a-f0-9]{40}$') { throw 'source-commit-not-pinned' }
    if ($Repository -cnotmatch '^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') { throw 'source-repository-not-pinned' }
    $root = Assert-PilotPath -Path $Root
    $top = Assert-PilotPath -Path (Invoke-PilotGit -Root $root -Arguments @('rev-parse', '--show-toplevel') -Clock $Clock -DeadlineSeconds $DeadlineSeconds)
    if ($top -cne $root -and -not ($script:PilotWindows -and $top -ieq $root)) { throw 'source-not-checkout-root' }
    $remote = Invoke-PilotGit -Root $root -Arguments @('remote', 'get-url', 'origin') -Clock $Clock -DeadlineSeconds $DeadlineSeconds
    if ($remote -cne $Repository -and $remote -cne ($Repository + '.git')) { throw 'source-wrong-repository' }
    $head = Invoke-PilotGit -Root $root -Arguments @('rev-parse', '--verify', 'HEAD') -Clock $Clock -DeadlineSeconds $DeadlineSeconds
    if ($head -cne $ExpectedCommit) { throw 'source-wrong-commit' }
    $tree = Invoke-PilotGit -Root $root -Arguments @('rev-parse', '--verify', 'HEAD^{tree}') -Clock $Clock -DeadlineSeconds $DeadlineSeconds
    if ($tree -cnotmatch '^[a-f0-9]{40}$' -or ($ExpectedTree -and $tree -cne $ExpectedTree)) { throw 'source-wrong-tree' }
    # Inventory/index comparisons avoid executing arbitrary configured clean filters through git status.
    # Include ignored/untracked files: no warm mutable runtime or hidden owner patch in a source checkout.
    foreach ($arguments in @(@('ls-files', '--others', '--exclude-standard', '-z'), @('ls-files', '--others', '--ignored', '--exclude-standard', '-z'))) {
        if (Invoke-PilotGit -Root $root -Arguments $arguments -Clock $Clock -DeadlineSeconds $DeadlineSeconds) { throw 'source-dirty-or-staged' }
    }
    # Windows PowerShell's Framework overloads otherwise bind scalar char plus
    # options to params char[], retaining a trailing empty inventory entry.
    $separators = [char[]]@([char]0)
    $index = (Invoke-PilotGit -Root $root -Arguments @('ls-files', '-v', '-z') -Clock $Clock -DeadlineSeconds $DeadlineSeconds).Split($separators, [StringSplitOptions]::RemoveEmptyEntries)
    foreach ($entry in $index) { if (-not $entry.StartsWith('H ', [StringComparison]::Ordinal)) { throw 'source-index-flags-unsupported' } }
    $tracked = (Invoke-PilotGit -Root $root -Arguments @('ls-tree', '-r', '-z', 'HEAD') -Clock $Clock -DeadlineSeconds $DeadlineSeconds).Split($separators, [StringSplitOptions]::RemoveEmptyEntries)
    if ($tracked.Count -ne $index.Count) { throw 'source-index-tree-count-mismatch' }
    $staged = (Invoke-PilotGit -Root $root -Arguments @('ls-files', '--stage', '-z') -Clock $Clock -DeadlineSeconds $DeadlineSeconds).Split($separators, [StringSplitOptions]::RemoveEmptyEntries)
    if ($staged.Count -ne $tracked.Count) { throw 'source-dirty-or-staged' }
    $fingerprints = New-Object 'System.Collections.Generic.List[string]'
    foreach ($entry in $tracked) {
        if ($null -ne $Clock) { Assert-PilotDeadline -Clock $Clock -DeadlineSeconds $DeadlineSeconds }
        if ($entry -cnotmatch '^(100644|100755) blob ([a-f0-9]{40})\t(.+)$') { throw 'source-tree-entry-unsupported' }
        $mode = $Matches[1]; $blobId = $Matches[2]; $relative = $Matches[3]
        if ($staged -cnotcontains ($mode + ' ' + $blobId + " 0`t" + $relative)) { throw 'source-dirty-or-staged' }
        $trackedPath = Assert-PilotPath -Path (Join-Path $root $relative) -File
        if ((Get-Item -LiteralPath $trackedPath -Force).Length -gt 16MB) { throw 'source-file-size-limit' }
        $bytes = [IO.File]::ReadAllBytes($trackedPath)
        if ((Get-PilotBlobId -Bytes $bytes) -cne $blobId) {
            # Only UTF-8 source text may vary by checkout LF/CRLF. No Git clean/smudge filter is executed or trusted.
            $extension = [IO.Path]::GetExtension($relative).ToLowerInvariant()
            if (@('.ps1', '.psm1', '.psd1', '.cs', '.py', '.json', '.yaml', '.yml', '.md', '.txt', '.sh', '.toml', '.cfg', '.ini', '.gitignore', '.gitattributes') -cnotcontains $extension -and
                @('.gitignore', '.gitattributes') -cnotcontains [IO.Path]::GetFileName($relative)) { throw 'source-public-blob-mismatch' }
            $utf8 = New-Object Text.UTF8Encoding($false, $true)
            $normalized = $utf8.GetBytes($utf8.GetString($bytes).Replace("`r`n", "`n"))
            if ((Get-PilotBlobId -Bytes $normalized) -cne $blobId) { throw 'source-public-blob-mismatch' }
        }
        $fingerprints.Add($relative + [char]0 + (Get-PilotDigest -Path $trackedPath))
    }
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try { $executedTree = ([BitConverter]::ToString($algorithm.ComputeHash([Text.Encoding]::UTF8.GetBytes([string]::Join("`n", $fingerprints))))).Replace('-', '').ToLowerInvariant() }
    finally { $algorithm.Dispose() }
    $digests = @()
    foreach ($pin in $Pins) {
        if ($null -ne $Clock) { Assert-PilotDeadline -Clock $Clock -DeadlineSeconds $DeadlineSeconds }
        if ([string]$pin.path -cnotmatch '^[A-Za-z0-9_./-]+$' -or ([string]$pin.path).Contains('..') -or [IO.Path]::IsPathRooted([string]$pin.path)) { throw 'pin-path-invalid' }
        if ([string]$pin.sha256Lf -cnotmatch '^[a-f0-9]{64}$') { throw 'pin-digest-invalid' }
        $path = Assert-PilotPath -Path (Join-Path $root $pin.path) -File
        $lf = Get-PilotDigest -Path $path -NormalizeText
        if ($lf -cne $pin.sha256Lf) { throw 'source-pin-mismatch' }
        $digests += [ordered]@{ path = [string]$pin.path; sha256Lf = $lf; executedBytesSha256 = (Get-PilotDigest -Path $path) }
    }
    return [pscustomobject][ordered]@{ repository = $Repository; commit = $head; tree = $tree; clean = $true;
        executedTreeSha256 = $executedTree; trackedFileCount = $tracked.Count; files = $digests }
}

function Set-PilotPrivateDirectory {
    param([string]$Path)
    if (-not $script:PilotWindows) { throw 'private-acl-requires-windows' }
    $null = Assert-PilotPath -Path $Path
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User
    $acl = New-Object Security.AccessControl.DirectorySecurity
    $acl.SetOwner($sid); $acl.SetAccessRuleProtection($true, $false)
    $inheritance = [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit
    $rule = New-Object Security.AccessControl.FileSystemAccessRule($sid, [Security.AccessControl.FileSystemRights]::FullControl,
        $inheritance, [Security.AccessControl.PropagationFlags]::None, [Security.AccessControl.AccessControlType]::Allow)
    [void]$acl.AddAccessRule($rule)
    # Fresh DACL only; no SACL read/write and no SeSecurityPrivilege dependency.
    $sections = [Security.AccessControl.AccessControlSections]::Owner -bor [Security.AccessControl.AccessControlSections]::Access
    if ($PSVersionTable.PSEdition -ceq 'Core') {
        [IO.FileSystemAclExtensions]::SetAccessControl((New-Object IO.DirectoryInfo($Path)), $acl)
        $actual = [IO.FileSystemAclExtensions]::GetAccessControl((New-Object IO.DirectoryInfo($Path)), $sections)
    }
    else {
        [IO.Directory]::SetAccessControl($Path, $acl)
        $actual = [IO.Directory]::GetAccessControl($Path, $sections)
    }
    $rules = @($actual.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]))
    if ($actual.GetOwner([Security.Principal.SecurityIdentifier]).Value -cne $sid.Value -or
        -not $actual.AreAccessRulesProtected -or $rules.Count -ne 1 -or $rules[0].IdentityReference.Value -cne $sid.Value -or
        $rules[0].IsInherited -or $rules[0].AccessControlType -ne [Security.AccessControl.AccessControlType]::Allow -or
        $rules[0].InheritanceFlags -ne $inheritance -or $rules[0].PropagationFlags -ne [Security.AccessControl.PropagationFlags]::None -or
        [int]$rules[0].FileSystemRights -ne [int][Security.AccessControl.FileSystemRights]::FullControl) { throw 'private-acl-verification-failed' }
}

function Write-PilotNewJson {
    param([string]$Path, [object]$Value)
    $null = Assert-PilotPath -Path $Path -AllowMissing
    $bytes = [Text.Encoding]::UTF8.GetBytes(($Value | ConvertTo-Json -Depth 16) + "`n")
    $stream = [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
    try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
    $null = Assert-PilotPath -Path $Path -File
}

function New-PilotLease {
    param([string]$EvidenceParent, [string]$CandidateCommit, [string]$ControllerCommit, [string]$SupervisorLeaseId = '',
        [string]$SupervisorStartedUtc = '', [string]$WorkParent = '')
    $parent = Assert-PilotPath -Path $EvidenceParent
    if (-not [IO.Directory]::Exists($parent)) { throw 'evidence-parent-not-directory' }
    $id = [Guid]::NewGuid().ToString('N')
    $root = Join-Path $parent ('runloc-whpx-' + $id)
    $work = $null
    $fixture = Join-Path $root 'fixture'
    if ($WorkParent) {
        $work = Get-PilotWorkPlan -WorkParent $WorkParent -LeaseId $id
        $WorkParent = $work.Parent; $fixture = $work.Fixture
        Assert-PilotFixtureSeparation -Fixture $fixture -ProtectedRoots @($root)
        if ([IO.Directory]::Exists($fixture) -or [IO.File]::Exists($fixture)) { throw 'fixture-already-exists' }
    }
    if ([IO.Directory]::Exists($root) -or [IO.File]::Exists($root)) { throw 'lease-already-exists' }
    [void][IO.Directory]::CreateDirectory($root)
    Set-PilotPrivateDirectory -Path $root
    $lock = [IO.File]::Open((Join-Path $root 'active.lock'), [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try {
        $private = Join-Path $root 'private'
        [void][IO.Directory]::CreateDirectory($private)
        $data = [ordered]@{ schemaVersion = 1; leaseId = $id; root = $root; candidateCommit = $CandidateCommit;
            controllerCommit = $ControllerCommit; createdUtc = [DateTime]::UtcNow.ToString('o');
            supervisorLeaseId = $SupervisorLeaseId; supervisorStartedUtc = $SupervisorStartedUtc;
            workParent = $WorkParent; fixture = $fixture }
        Write-PilotNewJson -Path (Join-Path $root 'lease.json') -Value $data
        $ownerDigest = Get-PilotDigest -Path (Join-Path $root 'lease.json')
        return [pscustomobject]@{ Id = $id; Root = $root; Private = $private; Fixture = $fixture; WorkParent = $WorkParent;
            Lock = $lock; OwnerDigest = $ownerDigest; CandidateCommit = $CandidateCommit; ControllerCommit = $ControllerCommit;
            FixtureCreated = $false; FixtureCreationDigest = '' }
    }
    catch { $lock.Dispose(); throw }
}

function Assert-PilotLease {
    param([object]$Lease)
    $root = Assert-PilotPath -Path $Lease.Root
    if ((Split-Path $root -Leaf) -cne ('runloc-whpx-' + $Lease.Id) -or $Lease.Id -cnotmatch '^[a-f0-9]{32}$') { throw 'lease-name-mismatch' }
    if ($null -eq $Lease.Lock -or -not $Lease.Lock.CanWrite) { throw 'lease-lock-not-held' }
    $path = Assert-PilotPath -Path (Join-Path $root 'lease.json') -File
    if ((Get-PilotDigest -Path $path) -cne $Lease.OwnerDigest) { throw 'lease-receipt-changed' }
    $owner = [IO.File]::ReadAllText($path) | ConvertFrom-Json
    if ($owner.leaseId -cne $Lease.Id -or $owner.root -cne $root -or $owner.candidateCommit -cne $Lease.CandidateCommit -or
        $owner.controllerCommit -cne $Lease.ControllerCommit) { throw 'lease-owner-mismatch' }
    $expectedFixture = Join-Path $root 'fixture'
    if ($Lease.WorkParent) { $expectedFixture = (Get-PilotWorkPlan -WorkParent $Lease.WorkParent -LeaseId $Lease.Id).Fixture }
    if ($Lease.Fixture -cne $expectedFixture -or $owner.fixture -cne $expectedFixture -or
        $owner.workParent -cne $Lease.WorkParent) { throw 'lease-fixture-mismatch' }
    $null = Assert-PilotPath -Path $Lease.Fixture -AllowMissing
}

function Remove-PilotFixture {
    param([object]$Lease, [Diagnostics.Stopwatch]$Clock, [double]$DeadlineSeconds, [bool]$OwnedProcessesExited)
    Assert-PilotLease -Lease $Lease
    if (-not $OwnedProcessesExited) { throw 'cleanup-process-ownership-unresolved' }
    $directoryExists = [IO.Directory]::Exists($Lease.Fixture)
    $fileExists = [IO.File]::Exists($Lease.Fixture)
    if (-not $directoryExists -and -not $fileExists) { return }
    # A planned path in lease.json is not creation authority. In particular,
    # finally must preserve a collision that New-PilotFixture refused to create.
    if ($Lease.FixtureCreated -isnot [bool] -or -not $Lease.FixtureCreated) { throw 'cleanup-fixture-not-created' }
    if (-not $directoryExists) { throw 'cleanup-fixture-not-directory' }
    if ($Lease.FixtureCreationDigest -cnotmatch '^[a-f0-9]{64}$') { throw 'cleanup-fixture-creation-unproven' }
    $creationPath = Assert-PilotPath -Path (Join-Path $Lease.Root 'fixture-created.json') -File
    if ((Get-PilotDigest -Path $creationPath) -cne $Lease.FixtureCreationDigest) { throw 'cleanup-fixture-creation-proof-changed' }
    $creation = [IO.File]::ReadAllText($creationPath) | ConvertFrom-Json
    if ($creation.schemaVersion -ne 1 -or $creation.leaseId -cne $Lease.Id -or $creation.fixture -cne $Lease.Fixture -or
        $creation.ownerDigest -cne $Lease.OwnerDigest -or $creation.createdBy -cne 'exclusive-directory-create') { throw 'cleanup-fixture-creation-proof-invalid' }
    $stack = New-Object 'System.Collections.Generic.Stack[string]'
    $directories = New-Object 'System.Collections.Generic.List[string]'
    $files = New-Object 'System.Collections.Generic.List[string]'
    $stack.Push($Lease.Fixture)
    # Validate the entire inventory before deleting anything; never follow a reparse point.
    while ($stack.Count) {
        Assert-PilotDeadline -Clock $Clock -DeadlineSeconds $DeadlineSeconds
        $directory = $stack.Pop(); $null = Assert-PilotPath -Path $directory
        $directories.Add($directory)
        foreach ($entry in [IO.Directory]::EnumerateFileSystemEntries($directory)) {
            if (-not (Test-PilotDescendant -Path $entry -Root $Lease.Fixture)) { throw 'cleanup-path-escape' }
            $null = Assert-PilotPath -Path $entry
            if ([IO.Directory]::Exists($entry)) { $stack.Push($entry) }
            else { $null = Assert-PilotPath -Path $entry -File; $files.Add($entry) }
            if (($files.Count + $directories.Count + $stack.Count) -gt 200000) { throw 'cleanup-inventory-limit' }
        }
    }
    foreach ($file in $files) {
        Assert-PilotDeadline -Clock $Clock -DeadlineSeconds $DeadlineSeconds
        $null = Assert-PilotPath -Path $file -File
        [IO.File]::SetAttributes($file, [IO.FileAttributes]::Normal)
        [IO.File]::Delete($file)
    }
    for ($index = $directories.Count - 1; $index -ge 0; $index--) {
        Assert-PilotDeadline -Clock $Clock -DeadlineSeconds $DeadlineSeconds
        $null = Assert-PilotPath -Path $directories[$index]
        [IO.Directory]::Delete($directories[$index], $false)
    }
    if ([IO.Directory]::Exists($Lease.Fixture)) { throw 'cleanup-fixture-still-exists' }
}

function New-PilotFixture {
    param([object]$Lease)
    Assert-PilotLease -Lease $Lease
    if ([IO.Directory]::Exists($Lease.Fixture) -or [IO.File]::Exists($Lease.Fixture)) { throw 'fixture-already-exists' }
    if ($Lease.FixtureCreated -isnot [bool] -or $Lease.FixtureCreated) { throw 'fixture-already-created' }
    if ($script:PilotWindows) {
        Import-PilotNative
        [RunlocPoc.OwnedProcess]::CreateNewDirectory($Lease.Fixture)
    }
    else { $null = New-Item -ItemType Directory -Path $Lease.Fixture -ErrorAction Stop }
    # Set only after exclusive creation succeeds. A failed/racing create cannot
    # authorize finally to delete another fixture. Incomplete durable proof
    # deliberately quarantines the new directory even when this latch is true.
    $Lease.FixtureCreated = $true
    $creationPath = Join-Path $Lease.Root 'fixture-created.json'
    Write-PilotNewJson -Path $creationPath -Value @{ schemaVersion = 1; leaseId = $Lease.Id; fixture = $Lease.Fixture;
        ownerDigest = $Lease.OwnerDigest; createdBy = 'exclusive-directory-create'; createdUtc = [DateTime]::UtcNow.ToString('o') }
    $Lease.FixtureCreationDigest = Get-PilotDigest -Path $creationPath
    if ($script:PilotWindows) { Set-PilotPrivateDirectory -Path $Lease.Fixture }
    Assert-PilotLease -Lease $Lease
}

function Invoke-PilotExactAclPreflight {
    param([string]$SourceRoot, [string]$ProbeDirectory)
    $null = Assert-PilotPath -Path $ProbeDirectory -AllowMissing
    if ([IO.Directory]::Exists($ProbeDirectory)) { throw 'acl-probe-already-exists' }
    [void][IO.Directory]::CreateDirectory($ProbeDirectory)
    $probe = Join-Path $ProbeDirectory 'not-a-key.txt'
    [IO.File]::WriteAllText($probe, 'Synthetic ACL probe. This is not a credential.', (New-Object Text.UTF8Encoding($false)))
    $module = Import-Module (Join-Path $SourceRoot 'src/EzVm/EzVm.psd1') -Force -PassThru -ErrorAction Stop
    & $module {
        param($Directory, $File)
        Set-EzVmPrivateAcl -Path $Directory -Directory
        Set-EzVmPrivateAcl -Path $File
        # Must execute the candidate's complete failing path, not only its generic ACL helper.
        Protect-EzVmControllerPrivateKey -Path $File
    } $ProbeDirectory $probe
    $null = Assert-PilotPath -Path $probe -File
}

function Invoke-PilotChild {
    param([string]$Executable, [string[]]$Arguments, [string]$WorkingDirectory, [string]$TemporaryDirectory,
        [string]$RawLogPath, [Diagnostics.Stopwatch]$Clock, [double]$ExecutionDeadlineSeconds,
        [double]$CleanupDeadlineSeconds, [long]$MaximumLogBytes = 16777216)
    Assert-PilotDeadline -Clock $Clock -DeadlineSeconds $ExecutionDeadlineSeconds
    Import-PilotNative
    $job = $null; $records = New-Object 'System.Collections.Generic.List[object]'
    $result = [ordered]@{ exitCode = $null; childExited = $false; activeProcesses = $null; forced = $false;
        timedOut = $false; cancelled = $false; outputOverflow = $false; outputFailed = $false;
        startSeconds = $Clock.Elapsed.TotalSeconds; endSeconds = $null; records = @(); ownership = $null }
    try {
        $job = New-Object RunlocPoc.OwnedProcess($Executable, $Arguments, $WorkingDirectory,
            $TemporaryDirectory, $RawLogPath, $MaximumLogBytes)
        $result.ownership = [ordered]@{ method = 'CreateProcess-suspended-then-Job-assignment'; pid = $job.ProcessId;
            createdUtc = $job.CreatedUtc; executableSha256 = (Get-PilotDigest -Path $Executable); killOnClose = $true;
            breakawayAllowed = $false }
        while (-not $job.HasExited) {
            foreach ($line in $job.Drain()) { $records.Add($line) }
            if ($Clock.Elapsed.TotalSeconds -ge $ExecutionDeadlineSeconds) { $result.timedOut = $true; break }
            if ($job.OutputOverflow -or $job.OutputFailed) { break }
            Start-Sleep -Milliseconds 100
        }
    }
    finally {
        if ($null -ne $job) {
            try {
                if (-not $job.HasExited -or $job.ActiveProcesses -gt 0) {
                    $result.forced = $true
                    $job.Terminate()
                    while ((-not $job.HasExited -or $job.ActiveProcesses -gt 0) -and $Clock.Elapsed.TotalSeconds -lt $CleanupDeadlineSeconds) {
                        Start-Sleep -Milliseconds 50
                    }
                }
                $result.childExited = $job.HasExited
                $result.activeProcesses = $job.ActiveProcesses
                if ($job.HasExited) { $result.exitCode = $job.ExitCode }
                $remainingMs = [int][Math]::Max(0.0, [Math]::Min(3000.0, ($CleanupDeadlineSeconds - $Clock.Elapsed.TotalSeconds) * 1000))
                if (-not $job.FinishOutput($remainingMs)) { $result.outputFailed = $true }
                foreach ($line in $job.Drain()) { $records.Add($line) }
                $result.outputOverflow = $job.OutputOverflow
                $result.outputFailed = $result.outputFailed -or $job.OutputFailed
            }
            finally { $job.Dispose() }
        }
        $result.endSeconds = $Clock.Elapsed.TotalSeconds
        $result.records = @($records.ToArray())
    }
    return [pscustomobject]$result
}

function Get-PilotFixtureIdentity {
    param([object]$Lease, [object[]]$Events, [string]$ExpectedImageSha256, [string]$ExpectedQemuVersion,
        [Diagnostics.Stopwatch]$Clock, [double]$DeadlineSeconds)
    Assert-PilotLease -Lease $Lease
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
        if ($manifest.build.accelerator -cne 'whpx' -or $manifest.source.imageSha256 -cne $ExpectedImageSha256 -or
            $manifest.baseSha256 -cnotmatch '^[a-f0-9]{64}$') { throw 'fixture-base-accelerator-or-identity-mismatch' }
        if ($baseDigest -and $baseDigest -cne $manifest.baseSha256) { throw 'fixture-base-relocation-mismatch' }
        $baseDigest = $manifest.baseSha256
        foreach ($toolName in @('qemu-system-x86_64.exe', 'qemu-img.exe')) {
            Assert-PilotDeadline -Clock $Clock -DeadlineSeconds $DeadlineSeconds
            $toolPath = Assert-PilotPath -Path (Join-Path $root ('runtime/qemu/' + $toolName)) -File
            $digest = Get-PilotDigest -Path $toolPath
            if ($rootName -ceq $roots[0]) { $binaries += [ordered]@{ name = $toolName; sha256 = $digest } }
            elseif ($digest -cne @($binaries | Where-Object { $_.name -ceq $toolName })[0].sha256) { throw 'fixture-relocated-tool-mismatch' }
        }
        foreach ($name in @('ezvm010-source', 'ezvm010-stateful', 'ezvm010-imported', 'ezvm012-secondary', 'ezvm012-fresh')) {
            $runtimePath = Assert-PilotPath -Path (Join-Path $root ('runtime/instances/' + $name + '/runtime.json')) -File
            $runtime = [IO.File]::ReadAllText($runtimePath) | ConvertFrom-Json
            if ($runtime.instanceName -cne $name -or $runtime.state -cne 'STOPPED' -or $runtime.accelerator -cne 'whpx' -or
                $runtime.launchId -cnotmatch '^[a-f0-9]{32}$') { throw 'fixture-guest-not-stopped-or-accelerator-mismatch' }
            $guests += [ordered]@{ root = $(if ($rootName -ceq $roots[0]) { 'A' } else { 'B' }); name = $name;
                state = 'STOPPED'; accelerator = 'whpx'; launchId = $runtime.launchId }
        }
    }
    return [pscustomobject][ordered]@{ expectedImageSha256 = $ExpectedImageSha256; sourceImageSha256 = $sourceEvents[0].value;
        baseImageSha256 = $baseDigest; baseId = $baseEvents[0].value; qemuVersion = $ExpectedQemuVersion; qemuBinaries = $binaries; guests = $guests }
}

function ConvertTo-PilotEvidenceEvent {
    param([string]$Line, [string]$Utc, [double]$Seconds)
    # Raw guest prose, exception text, paths, usernames and serial logs are never exported.
    if ($Line -cmatch '^(EZVM0(?:10|11|12)_[A-Z0-9_]+)=PASS$' -and $script:PilotMarkers -ccontains $Matches[1]) {
        return [pscustomobject]@{ kind = 'marker'; name = $Matches[1]; value = 'PASS'; utc = $Utc; seconds = $Seconds }
    }
    if ($Line -cmatch '^EZVM010_ACCELERATOR=(whpx|tcg)$') {
        return [pscustomobject]@{ kind = 'accelerator'; name = 'requested'; value = $Matches[1]; utc = $Utc; seconds = $Seconds }
    }
    if ($Line -cmatch '^EZVM010_(?:GRACEFUL_CLEANUP_ERROR|SOURCE_ROOT_RESTORE_ERROR|FAILED_AT)=' -or
        $Line -cmatch '^EZVM010_WHPX_EXECUTION=SKIP') {
        return [pscustomobject]@{ kind = 'failure'; name = 'harness-failure'; value = ''; utc = $Utc; seconds = $Seconds }
    }
    if ($Line -cmatch '^EZVM0(?:10|11)_STEP=([a-z_]+)(?:;|$)' -and $script:PilotSteps -ccontains $Matches[1]) {
        $step = $Matches[1]; $instance = ''
        if ($Line -cmatch '; instance=(ezvm010-source|ezvm010-stateful|ezvm010-imported|ezvm012-secondary|ezvm012-fresh)(?:;|$)') { $instance = $Matches[1] }
        return [pscustomobject]@{ kind = 'phase'; name = $step; value = $instance; utc = $Utc; seconds = $Seconds }
    }
    if ($Line -cmatch '^EZVM010_REAL_(SOURCE_SHA256|EXPORTED_SHA256)=([a-f0-9]{64})$') {
        return [pscustomobject]@{ kind = 'identity'; name = $Matches[1]; value = $Matches[2]; utc = $Utc; seconds = $Seconds }
    }
    if ($Line -cmatch '^EZVM010_REAL_QEMU=([0-9]+\.[0-9]+\.[0-9]+)$') {
        return [pscustomobject]@{ kind = 'identity'; name = 'qemu-version'; value = $Matches[1]; utc = $Utc; seconds = $Seconds }
    }
    if ($Line -cmatch '^EZVM010_REAL_BASE=([A-Za-z0-9._-]{1,128})$') {
        return [pscustomobject]@{ kind = 'identity'; name = 'base-id'; value = $Matches[1]; utc = $Utc; seconds = $Seconds }
    }
    if ($Line -cmatch '^EZVM010_(STARTED_AT|COMPLETED_AT)=([0-9T:.+Z-]+)$') {
        return [pscustomobject]@{ kind = 'boundary'; name = $Matches[1]; value = ''; utc = $Utc; seconds = $Seconds }
    }
    return $null
}

function Get-PilotPhaseDurations {
    param([object[]]$Events, [double]$TotalSeconds)
    $phases = @($Events | Where-Object { $_.kind -eq 'phase' -or ($_.kind -eq 'boundary' -and $_.name -eq 'COMPLETED_AT') } | Sort-Object seconds)
    $start = 0.0; $name = 'fresh-root-and-qemu-bootstrap'; $instance = ''; $result = @()
    foreach ($event in $phases) {
        $result += [ordered]@{ phase = $name; instance = $instance; startSeconds = $start;
            endSeconds = [double]$event.seconds; elapsedSeconds = [Math]::Max(0, [double]$event.seconds - $start) }
        $start = [double]$event.seconds; $name = [string]$event.name; $instance = [string]$event.value
    }
    $result += [ordered]@{ phase = $name; instance = $instance; startSeconds = $start;
        endSeconds = $TotalSeconds; elapsedSeconds = [Math]::Max(0, $TotalSeconds - $start) }
    return $result
}

function Assert-PilotTelemetryNumber {
    param([object]$Value, [switch]$Integer)
    if ($Value -isnot [int] -and $Value -isnot [long] -and $Value -isnot [double] -and $Value -isnot [decimal]) { throw 'telemetry-number-invalid' }
    $number = [double]$Value
    if ([double]::IsNaN($number) -or [double]::IsInfinity($number) -or $number -lt 0 -or
        ($Integer -and [Math]::Floor($number) -ne $number)) { throw 'telemetry-number-invalid' }
}

function Read-PilotTelemetry {
    param([string]$Path, [string]$OutputPath, [Diagnostics.Stopwatch]$Clock, [double]$DeadlineSeconds,
        [switch]$NoOverallTimeout)
    $null = Assert-PilotPath -Path $Path -File
    if ((Get-Item -LiteralPath $Path).Length -gt 8MB) { throw 'telemetry-size-limit' }
    $operations = @('full-release', 'verified-identity', 'Invoke-EzVmProcess', 'Assert-EzVmQemuPayloadIntegrity',
        'Test-EzVmPreparedBaseDirectory', 'Test-EzVmInstanceStorage', 'Test-EzVmPortableBundle', 'Get-EzVmDoctorReport',
        'Install-EzVmQemuRuntime', 'Invoke-EzVmSourceImageAcquire', 'Invoke-EzVmBaseBuild', 'Start-EzVmReadyInstance',
        'Stop-EzVmInstance', 'Copy-EzVmManagedInstance', 'Export-EzVmManagedInstance', 'Import-EzVmManagedInstance', 'Reset-EzVmManagedInstance')
    $categories = @('qualification', 'identity', 'process', 'validation', 'acquisition', 'base-build', 'ready', 'shutdown', 'image')
    $stack = New-Object 'System.Collections.Generic.Stack[object]'
    $public = New-Object 'System.Collections.Generic.List[object]'
    $groups = @{}; $identities = @(); $lastSeconds = 0.0; $nextOperation = 1; $sequence = 0; $rootTerminal = $null
    $lines = [IO.File]::ReadLines($Path).GetEnumerator()
    try {
        while ($lines.MoveNext()) {
            $line = [string]$lines.Current
            Assert-PilotDeadline -Clock $Clock -DeadlineSeconds $DeadlineSeconds
            if ($line.Length -gt 16384 -or ++$sequence -gt 20000) { throw 'telemetry-record-limit' }
            $record = $line | ConvertFrom-Json
            if ($record.schemaVersion -ne 1 -or $record.sequence -ne $sequence -or $operations -cnotcontains $record.operation -or
                $categories -cnotcontains $record.category -or @('start', 'end', 'failure', 'identity') -cnotcontains $record.event) { throw 'telemetry-record-invalid' }
            Assert-PilotTelemetryNumber -Value $record.elapsedSeconds
            Assert-PilotTelemetryNumber -Value $record.operationId -Integer
            if ($record.elapsedSeconds -lt $lastSeconds -or (-not $NoOverallTimeout -and $record.elapsedSeconds -gt 5400) -or $record.operationId -lt 1) { throw 'telemetry-clock-or-operation-invalid' }
            $lastSeconds = [double]$record.elapsedSeconds
            $utc = [DateTimeOffset]::MinValue
            if ($record.utc -is [DateTime] -or $record.utc -is [DateTimeOffset]) { $utc = [DateTimeOffset]$record.utc }
            elseif ($record.utc -isnot [string] -or -not [DateTimeOffset]::TryParse($record.utc, [ref]$utc)) { throw 'telemetry-utc-invalid' }
            $clean = [ordered]@{ schemaVersion = 1; sequence = $sequence; utc = $utc.ToUniversalTime().ToString('o');
                elapsedSeconds = [double]$record.elapsedSeconds; event = $record.event; operationId = $record.operationId;
                parentOperationId = $record.parentOperationId; operation = $record.operation; category = $record.category }
            if ($record.event -ceq 'identity') {
                if ($record.operation -cne 'verified-identity' -or $record.category -cne 'identity' -or $record.operationId -ne 1 -or
                    $null -ne $record.parentOperationId -or $stack.Count -eq 0) { throw 'telemetry-identity-context-invalid' }
                $details = $record.details
                if (@('qemu-system', 'qemu-img', 'source-image', 'prepared-base') -cnotcontains $details.kind -or $details.sha256 -cnotmatch '^[a-f0-9]{64}$') { throw 'telemetry-identity-invalid' }
                Assert-PilotTelemetryNumber -Value $details.sizeBytes -Integer
                $clean.details = [ordered]@{ kind = $details.kind; sha256 = $details.sha256; sizeBytes = $details.sizeBytes }
                if ($null -ne $details.PSObject.Properties['version']) {
                    if ($details.version -cnotmatch '^[A-Za-z0-9._+-]{1,64}$') { throw 'telemetry-version-invalid' }
                    $clean.details.version = $details.version
                }
                $identities += $clean.details
            }
            elseif ($record.event -ceq 'start') {
                if ($record.operationId -ne $nextOperation++) { throw 'telemetry-operation-sequence-invalid' }
                $parent = $null; if ($stack.Count) { $parent = $stack.Peek().operationId }
                if ($record.parentOperationId -ne $parent -or ($record.operationId -eq 1 -and
                    ($record.operation -cne 'full-release' -or $record.category -cne 'qualification')) -or
                    ($record.operationId -ne 1 -and $record.operation -ceq 'full-release') -or $stack.Count -gt 64) { throw 'telemetry-nesting-invalid' }
                $clean.details = [ordered]@{}
                if ($record.operation -ceq 'Invoke-EzVmProcess') {
                    if (@('qemu-img.exe', 'qemu-system-x86_64.exe', 'ssh.exe', 'scp.exe', 'other') -cnotcontains $record.details.tool) { throw 'telemetry-tool-invalid' }
                    $clean.details.tool = $record.details.tool
                    if ($null -ne $record.details.PSObject.Properties['action']) {
                        if (@('info', 'compare', 'create', 'convert', 'check', 'rebase', 'resize', '--version', 'other') -cnotcontains $record.details.action) { throw 'telemetry-action-invalid' }
                        $clean.details.action = $record.details.action
                    }
                }
                $stack.Push([pscustomobject]$clean)
            }
            else {
                if (-not $stack.Count) { throw 'telemetry-unmatched-terminal' }
                $start = $stack.Pop()
                if ($record.operationId -ne $start.operationId -or $record.parentOperationId -ne $start.parentOperationId -or
                    $record.operation -cne $start.operation -or $record.category -cne $start.category) { throw 'telemetry-nesting-invalid' }
                Assert-PilotTelemetryNumber -Value $record.durationSeconds
                if (-not $NoOverallTimeout -and $record.durationSeconds -gt 5400) { throw 'telemetry-duration-invalid' }
                $clean.durationSeconds = [double]$record.durationSeconds
                $clean.digestTotals = [ordered]@{}
                foreach ($property in $record.digestTotals.PSObject.Properties) {
                    if (@('manifest', 'qemu-payload', 'base-image', 'source-image', 'other') -cnotcontains $property.Name) { throw 'telemetry-digest-kind-invalid' }
                    $total = $property.Value
                    foreach ($field in @('calls', 'failedCalls', 'bytes')) { Assert-PilotTelemetryNumber -Value $total.$field -Integer }
                    Assert-PilotTelemetryNumber -Value $total.elapsedSeconds
                    if ($total.failedCalls -gt $total.calls -or (-not $NoOverallTimeout -and $total.elapsedSeconds -gt 5400)) { throw 'telemetry-digest-total-invalid' }
                    $clean.digestTotals[$property.Name] = [ordered]@{ calls = $total.calls; failedCalls = $total.failedCalls;
                        bytes = $total.bytes; elapsedSeconds = [double]$total.elapsedSeconds }
                }
                $key = $record.operation + '/' + $record.category
                if (-not $groups.ContainsKey($key)) { $groups[$key] = [ordered]@{ operation = $record.operation; category = $record.category; calls = 0; failedCalls = 0; inclusiveSeconds = 0.0 } }
                $groups[$key].calls++; $groups[$key].inclusiveSeconds += [double]$record.durationSeconds
                if ($record.event -ceq 'failure') { $groups[$key].failedCalls++ }
                if ($record.operationId -eq 1) {
                    if ($null -ne $rootTerminal) { throw 'telemetry-duplicate-root-terminal' }
                    $rootTerminal = $clean
                }
            }
            if ($null -ne $rootTerminal -and $record.operationId -ne 1) { throw 'telemetry-after-root-terminal' }
            $public.Add([pscustomobject]$clean)
        }
    }
    finally { $lines.Dispose() }
    if ($sequence -eq 0 -or $stack.Count -ne 0 -or $null -eq $rootTerminal -or
        $public[$public.Count - 1].operation -cne 'full-release') { throw 'telemetry-incomplete' }
    $digest = Get-PilotDigest -Path $Path
    Write-PilotNewJson -Path $OutputPath -Value @{ schemaVersion = 1; events = @($public.ToArray()) }
    return [pscustomobject][ordered]@{ schemaVersion = 1; complete = ($rootTerminal.event -ceq 'end'); recordCount = $sequence;
        privateSourceSha256 = $digest; publicFile = [IO.Path]::GetFileName($OutputPath); publicSha256 = (Get-PilotDigest -Path $OutputPath);
        elapsedSeconds = $rootTerminal.elapsedSeconds; digestTotals = $rootTerminal.digestTotals;
        operations = @($groups.GetEnumerator() | Sort-Object Name | ForEach-Object { $_.Value }); identities = $identities;
        interpretation = 'Inclusive nested durations overlap. Root digest counters count each hash once. Nested failures include required negative controls.' }
}

function Assert-PilotTimingPolicy {
    param([object]$Receipt, [bool]$NoOverallTimeout)
    $property = $Receipt.PSObject.Properties['overallTimeoutDisabled']
    # Old bounded receipts remain readable. The exception always requires an
    # explicit boolean and independently supplied matching operator policy.
    if ($null -eq $property) { if ($NoOverallTimeout) { throw 'receipt-timing-policy-missing' } }
    elseif ($property.Value -isnot [bool] -or $property.Value -ne $NoOverallTimeout) { throw 'receipt-timing-policy-mismatch' }
    $target = if ($NoOverallTimeout) { 0 } else { 3600 }
    $wall = if ($NoOverallTimeout) { 0 } else { 5400 }
    foreach ($field in @('targetSeconds', 'hardWallSeconds')) {
        if ($Receipt.$field -isnot [int] -and $Receipt.$field -isnot [long]) { throw 'receipt-timing-policy-type' }
    }
    if ($Receipt.targetSeconds -ne $target -or $Receipt.hardWallSeconds -ne $wall) { throw 'receipt-timing-policy-invalid' }
}

function Test-PilotOutcome {
    param([object]$Receipt, [string]$LeaseId, [string]$CandidateCommit, [string]$ControllerCommit,
        [switch]$NoOverallTimeout)
    $reasons = New-Object 'System.Collections.Generic.List[string]'
    try {
        Assert-PilotTimingPolicy -Receipt $Receipt -NoOverallTimeout ([bool]$NoOverallTimeout)
        if ($Receipt.schemaVersion -isnot [int] -and $Receipt.schemaVersion -isnot [long]) { throw 'receipt-schema-type' }
        foreach ($field in @('preflightOnly', 'vmQualificationStarted', 'sourceUnchanged', 'timedOut', 'cancelled',
                'outputOverflow', 'outputFailed', 'harnessFailure', 'controllerFailure')) {
            if ($Receipt.$field -isnot [bool]) { throw 'receipt-boolean-type' }
        }
        foreach ($field in @('childExited', 'fixtureRemoved', 'forced', 'ownershipVerified')) {
            if ($Receipt.cleanup.$field -isnot [bool]) { throw 'receipt-cleanup-boolean-type' }
        }
        foreach ($value in @($Receipt.hardWallSeconds, $Receipt.childExitCode,
                $Receipt.preflight.exitCode, $Receipt.telemetry.recordCount)) {
            if ($value -isnot [int] -and $value -isnot [long]) { throw 'receipt-integer-type' }
        }
        # The native Job query returns UInt32. The controller validates these
        # counters before serialization; no string, bool or floating coercion is allowed.
        foreach ($value in @($Receipt.cleanup.activeProcesses, $Receipt.preflight.activeProcesses)) {
            if ($value -isnot [int] -and $value -isnot [long] -and $value -isnot [uint32]) { throw 'receipt-process-count-type' }
        }
        Assert-PilotTelemetryNumber -Value $Receipt.elapsedSeconds
        Assert-PilotRecordedWorkBudget -Budget $Receipt.pathBudget
        foreach ($source in @($Receipt.candidate, $Receipt.controller)) {
            if ($source.clean -isnot [bool] -or -not $source.clean -or $source.commit -cnotmatch '^[a-f0-9]{40}$' -or
                $source.tree -cnotmatch '^[a-f0-9]{40}$' -or $source.executedTreeSha256 -cnotmatch '^[a-f0-9]{64}$') { throw 'receipt-source-identity' }
        }
        if ($Receipt.host.standardUser -isnot [bool] -or -not $Receipt.host.standardUser -or
            $Receipt.host.seSecurityPrivilegePresent -isnot [bool] -or $Receipt.host.seSecurityPrivilegePresent) { throw 'receipt-privilege-proof' }
        if ($Receipt.telemetry.complete -isnot [bool] -or $Receipt.preflight.childExited -isnot [bool] -or
            $Receipt.preflight.forced -isnot [bool]) { throw 'receipt-preflight-type' }
        if ($Receipt.schemaVersion -ne 1 -or $Receipt.leaseId -cne $LeaseId -or $LeaseId -cnotmatch '^[a-f0-9]{32}$') { $reasons.Add('receipt-stale-or-wrong-lease') }
        if ($Receipt.candidate.commit -cne $CandidateCommit -or $Receipt.controller.commit -cne $ControllerCommit -or
            $Receipt.candidate.repository -cne 'https://github.com/techrote/ezvm' -or $Receipt.controller.repository -cne 'https://github.com/techrote/runloc') { $reasons.Add('receipt-source-mismatch') }
        if ($Receipt.preflightOnly -or -not $Receipt.vmQualificationStarted) { $reasons.Add('not-full-qualification') }
        if ($Receipt.childExitCode -ne 0) { $reasons.Add('child-failed') }
        if (-not $Receipt.preflight.childExited -or $Receipt.preflight.exitCode -ne 0 -or
            $Receipt.preflight.activeProcesses -ne 0 -or $Receipt.preflight.forced) { $reasons.Add('preflight-incomplete') }
        if (-not $Receipt.sourceUnchanged) { $reasons.Add('source-changed') }
        if ($Receipt.requestedAccelerator -cne 'whpx' -or $Receipt.observedAccelerator -cne 'whpx') { $reasons.Add('accelerator-mismatch') }
        if ($Receipt.timedOut -or $Receipt.cancelled -or $Receipt.outputOverflow -or $Receipt.outputFailed -or $Receipt.harnessFailure -or $Receipt.controllerFailure) { $reasons.Add('run-incomplete') }
        if (-not $Receipt.telemetry.complete -or $Receipt.telemetry.recordCount -lt 6 -or $Receipt.telemetry.recordCount -gt 20000 -or
            $Receipt.telemetry.publicSha256 -cnotmatch '^[a-f0-9]{64}$' -or $Receipt.telemetry.publicFile -cne 'telemetry-events.json') { $reasons.Add('telemetry-incomplete') }
        if ($Receipt.elapsedSeconds -le 0 -or (-not $NoOverallTimeout -and $Receipt.elapsedSeconds -gt 3600)) { $reasons.Add('target-unmet') }
        if (-not $Receipt.cleanup.childExited -or $Receipt.cleanup.activeProcesses -ne 0 -or
            -not $Receipt.cleanup.fixtureRemoved -or $Receipt.cleanup.forced -or -not $Receipt.cleanup.ownershipVerified) { $reasons.Add('cleanup-incomplete-or-forced') }
        foreach ($field in @('startSeconds', 'endSeconds')) { Assert-PilotTelemetryNumber -Value $Receipt.cleanup.$field }
        if ($Receipt.cleanup.startSeconds -gt $Receipt.cleanup.endSeconds -or $Receipt.cleanup.endSeconds -gt $Receipt.elapsedSeconds) { $reasons.Add('cleanup-time-invalid') }
        $started = [DateTimeOffset]$Receipt.startedUtc; $ended = [DateTimeOffset]$Receipt.endedUtc
        if ($ended -lt $started -or [Math]::Abs(($ended - $started).TotalSeconds - $Receipt.elapsedSeconds) -gt 2) { $reasons.Add('wall-time-invalid') }
        $events = @($Receipt.events); $lastSeconds = 0.0
        if ($events.Count -gt 10000) { throw 'receipt-event-limit' }
        foreach ($event in $events) {
            if ($event.kind -isnot [string] -or $event.name -isnot [string] -or $event.value -isnot [string]) { throw 'receipt-event-type' }
            Assert-PilotTelemetryNumber -Value $event.seconds
            if ($event.seconds -lt $lastSeconds -or $event.seconds -gt $Receipt.elapsedSeconds) { throw 'receipt-event-clock' }
            $eventUtc = [DateTimeOffset]$event.utc
            if ($eventUtc -lt $started -or $eventUtc -gt $ended) { throw 'receipt-event-utc' }
            $lastSeconds = [double]$event.seconds
        }
        if (@($events | Where-Object { $_.kind -ceq 'failure' }).Count) { $reasons.Add('harness-failure-event') }
        $seen = @($events | Where-Object { $_.kind -ceq 'marker' -and $_.value -ceq 'PASS' } | ForEach-Object { $_.name })
        foreach ($marker in $script:PilotMarkers) { if (@($seen | Where-Object { $_ -ceq $marker }).Count -ne 1) { $reasons.Add('marker-missing-or-duplicate:' + $marker) } }
        $accelerators = @($events | Where-Object { $_.kind -ceq 'accelerator' })
        if ($accelerators.Count -ne 1 -or $accelerators[0].value -cne 'whpx') { $reasons.Add('accelerator-evidence-invalid') }
        $begin = @($events | Where-Object { $_.kind -ceq 'boundary' -and $_.name -ceq 'STARTED_AT' })
        $end = @($events | Where-Object { $_.kind -ceq 'boundary' -and $_.name -ceq 'COMPLETED_AT' })
        if ($begin.Count -ne 1 -or $end.Count -ne 1 -or $end[0].seconds -le $begin[0].seconds) { $reasons.Add('boundary-evidence-invalid') }
        else {
            foreach ($event in @($events | Where-Object { $_.kind -ceq 'marker' -or $_.kind -ceq 'accelerator' })) {
                if ($event.seconds -le $begin[0].seconds -or $event.seconds -ge $end[0].seconds) { $reasons.Add('marker-outside-boundaries'); break }
            }
        }
        if ($Receipt.identities.sourceImageSha256 -cnotmatch '^[a-f0-9]{64}$' -or
            $Receipt.identities.sourceImageSha256 -cne $Receipt.identities.expectedImageSha256 -or
            $Receipt.identities.baseImageSha256 -cnotmatch '^[a-f0-9]{64}$' -or $Receipt.identities.baseId -cnotmatch '^[A-Za-z0-9._-]{1,128}$') { $reasons.Add('image-identity-incomplete') }
        $tools = @($Receipt.identities.qemuBinaries)
        if ($tools.Count -ne 2) { $reasons.Add('tool-identity-incomplete') }
        foreach ($name in @('qemu-system-x86_64.exe', 'qemu-img.exe')) {
            $found = @($tools | Where-Object { $_.name -ceq $name })
            if ($found.Count -ne 1 -or $found[0].sha256 -cnotmatch '^[a-f0-9]{64}$') { $reasons.Add('tool-identity-invalid') }
        }
        $guests = @($Receipt.identities.guests)
        if ($guests.Count -ne 10) { $reasons.Add('guest-identity-incomplete') }
        foreach ($root in @('A', 'B')) {
            foreach ($name in @('ezvm010-source', 'ezvm010-stateful', 'ezvm010-imported', 'ezvm012-secondary', 'ezvm012-fresh')) {
                $found = @($guests | Where-Object { $_.root -ceq $root -and $_.name -ceq $name })
                if ($found.Count -ne 1 -or $found[0].state -cne 'STOPPED' -or $found[0].accelerator -cne 'whpx' -or
                    $found[0].launchId -cnotmatch '^[a-f0-9]{32}$') { $reasons.Add('guest-identity-invalid') }
            }
        }
    }
    catch { $reasons.Add('receipt-malformed-or-incomplete') }
    return [pscustomobject]@{ Passed = ($reasons.Count -eq 0); Reasons = @($reasons.ToArray()) }
}
