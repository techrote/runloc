#requires -Version 5.1
# Shared BCL-only invocation gate. Loading this file defines a function only.
# Callers must pass their actual native command line and invocation identity.
function Test-PilotEarlyDedicatedFileInvocation {
    param([string[]]$CommandLine, [string]$ExpectedScript, [string]$InvocationName)
    # BCL-only: reject an owner-shell invocation before autoloading a cmdlet or
    # changing process environment. The compiled guard below remains mandatory.
    if ($null -eq $CommandLine -or $InvocationName -ceq '.' -or [string]::IsNullOrEmpty($ExpectedScript)) { return $false }
    $noProfile = $false; $nonInteractive = $false
    for ($index = 1; $index -lt $CommandLine.Length; $index++) {
        $argument = $CommandLine[$index]
        if ([string]::Equals($argument, '-NoProfile', [StringComparison]::OrdinalIgnoreCase)) { $noProfile = $true; continue }
        if ([string]::Equals($argument, '-NonInteractive', [StringComparison]::OrdinalIgnoreCase)) { $nonInteractive = $true; continue }
        if ([string]::Equals($argument, '-NoLogo', [StringComparison]::OrdinalIgnoreCase)) { continue }
        if ([string]::Equals($argument, '-ExecutionPolicy', [StringComparison]::OrdinalIgnoreCase)) {
            $index++
            if ($index -ge $CommandLine.Length -or -not [string]::Equals($CommandLine[$index], 'Bypass', [StringComparison]::OrdinalIgnoreCase)) { return $false }
            continue
        }
        if (-not [string]::Equals($argument, '-File', [StringComparison]::OrdinalIgnoreCase)) { return $false }
        $index++
        if ($index -ge $CommandLine.Length) { return $false }
        try {
            $comparison = if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
            return $noProfile -and $nonInteractive -and [string]::Equals([IO.Path]::GetFullPath($CommandLine[$index]), [IO.Path]::GetFullPath($ExpectedScript), $comparison)
        }
        catch { return $false }
    }
    return $false
}
