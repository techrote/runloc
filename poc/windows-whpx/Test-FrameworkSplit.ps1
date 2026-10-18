#requires -Version 5.1
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# .NET Framework has these six String.Split overloads, but no scalar char +
# StringSplitOptions overload. Keep that surface available on PS7 as well, so a
# modern runtime cannot hide the PS5.1 overload-selection regression.
# https://github.com/microsoft/referencesource/blob/main/mscorlib/system/string.cs
if (-not ('RunlocPoc.Tests.FrameworkSplitSurface' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
namespace RunlocPoc.Tests
{
    public sealed class FrameworkSplitSurface
    {
        readonly string text;
        public string Selected;
        public FrameworkSplitSurface(string text) { this.text = text; }
        public string[] Split(params char[] separator)
        { Selected = "params char[]"; return text.Split(separator); }
        public string[] Split(char[] separator, int count)
        { Selected = "char[], count"; return text.Split(separator, count); }
        public string[] Split(char[] separator, StringSplitOptions options)
        { Selected = "char[], options"; return text.Split(separator, options); }
        public string[] Split(char[] separator, int count, StringSplitOptions options)
        { Selected = "char[], count, options"; return text.Split(separator, count, options); }
        public string[] Split(string[] separator, StringSplitOptions options)
        { Selected = "string[], options"; return text.Split(separator, options); }
        public string[] Split(string[] separator, int count, StringSplitOptions options)
        { Selected = "string[], count, options"; return text.Split(separator, count, options); }
    }
}
'@ -ErrorAction Stop
}

function Assert-FrameworkInventory {
    param([string[]]$Actual, [string[]]$Expected, [string]$Label)
    if ($Actual.Count -ne $Expected.Count) { throw ($Label + ': wrong inventory count') }
    for ($index = 0; $index -lt $Expected.Count; $index++) {
        if ($Actual[$index] -cne $Expected[$index]) { throw ($Label + ': changed inventory entry') }
    }
}

$expected = @('H src/one.ps1', 'H docs/with spaces.md')
$inventory = [string]::Join([string][char]0, $expected) + [char]0
$legacy = New-Object RunlocPoc.Tests.FrameworkSplitSurface($inventory)
$broken = $legacy.Split([char]0, [StringSplitOptions]::RemoveEmptyEntries)
if ($legacy.Selected -cne 'params char[]' -or $broken.Count -ne 3 -or $broken[2] -cne '') {
    throw 'The legacy overload surface did not reproduce the trailing empty Git inventory entry.'
}

# The explicit array preserves complete NUL-delimited paths and excludes the
# terminator. Exercise both the legacy overload surface and this runtime's real
# String implementation; do not infer compatibility from source text.
$fixed = $legacy.Split([char[]]@([char]0), [StringSplitOptions]::RemoveEmptyEntries)
if ($legacy.Selected -cne 'char[], options') { throw 'The intended Framework overload was not selected.' }
Assert-FrameworkInventory -Actual $fixed -Expected $expected -Label 'Framework inventory'
Assert-FrameworkInventory -Actual ($inventory.Split([char[]]@([char]0), [StringSplitOptions]::RemoveEmptyEntries)) -Expected $expected -Label 'Native inventory'

# Lowercase/skip-worktree flags and an unexpected control character must survive
# parsing for the source verifier to reject or inspect; the options enum must
# never become a second separator or silently repair a bad index entry.
$negativeEntries = @('h src/modified.ps1', 'S src/skipped.ps1', ('H docs/name' + [char]1 + 'part.md'))
$negative = [string]::Join([string][char]0, $negativeEntries) + [char]0
$legacyNegative = New-Object RunlocPoc.Tests.FrameworkSplitSurface($negative)
Assert-FrameworkInventory -Actual ($legacyNegative.Split([char[]]@([char]0), [StringSplitOptions]::RemoveEmptyEntries)) -Expected $negativeEntries -Label 'Framework negative inventory'
Assert-FrameworkInventory -Actual ($negative.Split([char[]]@([char]0), [StringSplitOptions]::RemoveEmptyEntries)) -Expected $negativeEntries -Label 'Native negative inventory'
$brokenNegative = $legacyNegative.Split([char]0, [StringSplitOptions]::RemoveEmptyEntries)
if ($brokenNegative.Count -ne 5 -or $brokenNegative -ccontains $negativeEntries[2]) {
    throw 'The legacy overload did not reproduce unintended control-character splitting.'
}

foreach ($text in @('', [string][char]0)) {
    $empty = $text.Split([char[]]@([char]0), [StringSplitOptions]::RemoveEmptyEntries)
    Assert-FrameworkInventory -Actual $empty -Expected @() -Label 'Empty native inventory'
}
Write-Host 'PASS Framework NUL inventory overload regression; no VM or physical qualification was run.'
