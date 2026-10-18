# CI-POC-001 Windows/WHPX pilot

The current development manifest advances to an eight-CPU CI-POC-002 successor.
It is not yet physically qualified. CI-POC-001's accepted result below remains
bound to its historical exact sources. See [the runner lifecycle](RUNNER.md)
for the new Actions qualification and reusable backing-environment boundary.

This standalone helper runs EzVM's complete existing Windows release and
portability qualification from an immutable public candidate. It adds source
verification, exact synthetic ACL preflight, owned process containment, timing
and independently checked evidence. It does not install the Runloc product or
register a GitHub runner.

**Complete cold physical qualification passed on 18 October 2026**, with the
owner-authorized `-NoOverallTimeout` policy, in 6,791.4463709 supervised seconds.
See the [exact-source receipt and limitations](../../docs/fast-track/evidence/physical-whpx-20261018-complete-pass-analysis.json).
This does not meet the former 60-minute target or qualify the default bounded
policy. Software tests and `-PreflightOnly` alone do not satisfy
[issue #21](https://github.com/techrote/runloc/issues/21).
The [implementation checkpoint](../../docs/fast-track/CI-POC-001-EVIDENCE.md)
records current upstream work, actual results and the remaining merge gate.
The [binding contract](../../docs/fast-track/WINDOWS-WHPX-CI-POC.md) requires one
complete cold physical WHPX run within 60 minutes, including preflight, evidence
and owned cleanup, with an operational 90-minute wall in the default mode.
The owner's later 17 October 2026 instruction authorizes `-NoOverallTimeout`
for the replacement attempt after a forced Windows restart. That explicit mode
removes both the whole-invocation target and hard cutoff; it preserves the
original harness's per-operation limits and every other acceptance assertion.

## Candidate and source contract

[`candidate.json`](candidate.json) is the reviewed software execution manifest.
Its repository, exact commit, exact tree, original full harness and selected
LF-normalized SHA-256 pins must describe a public EzVM commit containing the ACL
repair and additive qualification telemetry. `executionApproved: true` means the
software candidate is approved to attempt execution; it does not mean physical
qualification passed. An unapproved or placeholder manifest refuses execution.
Candidate updates are reviewed and committed in Runloc, not patched into the
operator's checkout. Review includes the
[measured work-path budget](../../docs/fast-track/evidence/windows-path-budget.json):
changes to the harness, archive or extraction/base/relocation path definitions
require rechecking its bounds before approving a successor. The recorded upstream
PR disposition may still be draft;
approval of this frozen candidate does not merge an upstream PR or call it main.

The current candidate pins a checked QEMU 11.1.2 reset overlay in addition to
the original provider installer. EzVM verifies the original complete payload,
the ten-file overlay and the complete final payload before executable probing.
Its normal managed bootstrap acquires the published immutable asset bytes;
the full pilot uses no diagnostic tool provider. The controller compares the
effective overlay version exactly, while keeping the original provider identity
separate. See the candidate's source/build manifest and the
[successor path audit](../../docs/fast-track/evidence/windows-path-budget-qemu-overlay.json).
The overlay's new longest relative path is 152 UTF-16 units, below the existing
215-unit reserve; the 20-unit WorkParent limit is unchanged.

`-ExpectedControllerCommit` is the independently reviewed public Runloc SHA.
Supply it explicitly from the review record. The helper verifies both source
roots before execution and afterward. It rejects a wrong origin, wrong commit or
tree, staged changes, untracked or ignored content, unsupported file modes,
symlinks, hardlinks and index flags such as `assume-unchanged` or `skip-worktree`.
Every tracked file must match its public Git blob; supported UTF-8 source text
may differ only by CRLF/LF newlines. Git clean filters are never trusted or run to
establish source identity. Receipts record a SHA-256 identity of all actual
tracked bytes as well as the selected normalized pins, so an execution-time
change remains a failure even when the public tree ID is unchanged.

Use separate fresh checkouts for the qualification. Repository tests that leave
ignored caches or diagnostics should run in a separate test checkout. A prior
EzVM runtime or owner checkout is not a qualification source. The controller,
candidate and evidence parent must be separate local directory trees. Disposable
qualification storage uses a separate existing `WorkParent`. That parent may be
a common ancestor, such as the user profile, but the exact new fixture must be
disjoint from both sources and the evidence tree.

## Physical host prerequisites

Use a native Windows x64 host with working WHPX, local NTFS storage and Windows
PowerShell 5.1. Run as an ordinary non-elevated user whose token does not contain
`SeSecurityPrivilege`, including a disabled instance of that privilege. The
helper refuses administrator tokens and does not grant privileges or change host
virtualization, firewall, services or drivers. At preflight the host must have at
least 16 GiB free physical memory and 60 GiB free space on the work volume.
Downloads need ordinary outbound network access. No GitHub credential or JIT
runner payload is needed.

The canonical `WorkParent` must fit **20 UTF-16 code units**, excluding its trailing
separator. The helper adds a 23-character fixture name encoding the full random
128-bit lease ID, keeping the original harness's longest extracted file within
259 code units. For example, `C:\Users\runneradmin` fits; a typical profile's
`AppData\Local\Temp` does not. Use a short directory that already exists and is
writable by the ordinary user. A path that does not fit refuses before the
qualification fixture, downloads or VMs are created. Do not change Windows path
policy or elevate to work around this check.

The canonical evidence parent must fit 99 code units to leave room for both
supervisors' private metadata and the synthetic ACL probe. Sources/evidence can
use the ordinary user's application-data directory independently of `WorkParent`.

Use an operator-assigned `HostLabel` such as `lab-win11-01`. Do not put a username,
hostname or other private identifier into that label. Public evidence includes
the label, CPU model, Windows version/build, memory and storage observations and
PowerShell identity; it does not need an account name or source path.

Prepare a fresh local directory hierarchy and replace the placeholder below
with the reviewed public controller SHA. Each native Git command must succeed
before continuing:

```powershell
$controllerCommit = '<reviewed-public-Runloc-40-character-commit>'
$workParent = [Environment]::GetFolderPath('UserProfile')
if ([IO.Path]::GetFullPath($workParent).Length -gt 20) {
    throw 'Choose a shorter existing user-writable WorkParent before continuing.'
}
$pilotRoot = Join-Path ([Environment]::GetFolderPath('UserProfile')) ('Runloc-Pilot-' + [Guid]::NewGuid().ToString('N'))
if ((Join-Path $pilotRoot 'Evidence').Length -gt 99) {
    throw 'Choose a shorter existing user-owned parent for the fresh source/evidence hierarchy.'
}
New-Item -ItemType Directory -Path $pilotRoot -ErrorAction Stop | Out-Null
$controllerRoot = Join-Path $pilotRoot 'Controller'
$candidateRoot = Join-Path $pilotRoot 'EzVM'
$evidenceParent = Join-Path $pilotRoot 'Evidence'

git clone --no-checkout https://github.com/techrote/runloc $controllerRoot
if ($LASTEXITCODE -ne 0) { throw 'Controller clone failed.' }
git -C $controllerRoot config core.autocrlf false
if ($LASTEXITCODE -ne 0) { throw 'Controller checkout configuration failed.' }
git -C $controllerRoot config core.eol lf
if ($LASTEXITCODE -ne 0) { throw 'Controller default newline configuration failed.' }
git -C $controllerRoot checkout --detach $controllerCommit
if ($LASTEXITCODE -ne 0) { throw 'Controller checkout failed.' }

$candidate = Get-Content -Raw (Join-Path $controllerRoot 'poc\windows-whpx\candidate.json') | ConvertFrom-Json
if ($candidate.executionApproved -isnot [bool] -or -not $candidate.executionApproved) {
    throw 'This reviewed controller has no approved execution candidate.'
}
git clone --no-checkout $candidate.repository $candidateRoot
if ($LASTEXITCODE -ne 0) { throw 'Candidate clone failed.' }
git -C $candidateRoot config core.autocrlf false
if ($LASTEXITCODE -ne 0) { throw 'Candidate checkout configuration failed.' }
git -C $candidateRoot config core.eol lf
if ($LASTEXITCODE -ne 0) { throw 'Candidate default newline configuration failed.' }
git -C $candidateRoot checkout --detach $candidate.commit
if ($LASTEXITCODE -ne 0) { throw 'Candidate checkout failed.' }
New-Item -ItemType Directory -Path $evidenceParent -ErrorAction Stop | Out-Null

$entryPoint = Join-Path $controllerRoot 'poc\windows-whpx\Invoke-WhpxPilot.ps1'
$powershellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
```

The commands intentionally create new checkouts and a new evidence parent. If a
chosen path already contains work, choose another location. Do not remove owner
files or reuse old fixtures to make these prerequisites pass.

Use a direct local path that Git reports as the same canonical checkout root.
The physical operator session on 17 October 2026 observed MSIX redirection of
`LocalApplicationData` into the desktop app's package cache; the source guard
correctly refused that alias. The user profile provided a direct path with the
permissions required to create private owner-only directories. A merely writable
directory may lack the access required to apply those ACLs. Both conditions must
pass the unchanged preflight; do not weaken source or ACL checks to accommodate
an unsuitable parent. Explicit `core.eol lf` also prevents an inherited
`core.eol=crlf` from changing extensionless files such as `LICENSE`; repository
attributes still select CRLF for PowerShell scripts.

## Invoke the bounded pilot

Always launch a **dedicated** `powershell.exe -File` process. Do not dot-source the
entry point, call it directly in an interactive shell, or invoke the internal
controller. The outer process must own its lifetime because its native terminal
watchdog may end that process.

First, the optional inexpensive probe can verify this host and exact candidate:

```powershell
& $powershellExe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $entryPoint `
    -CandidateRoot $candidateRoot -ExpectedControllerCommit $controllerCommit `
    -EvidenceParent $evidenceParent -WorkParent $workParent -HostLabel 'lab-win11-01' -PreflightOnly
$preflightExitCode = $LASTEXITCODE
if ($preflightExitCode -ne 0) { throw "Preflight failed with exit $preflightExitCode; inspect its private attempt." }
```

This runs the actual pinned `Set-EzVmPrivateAcl` directory/file paths and
`Protect-EzVmControllerPrivateKey` on newly created synthetic non-key text. Its
probe succeeds before any qualification fixture, image download or VM start.
The result is `preflight-pass` with `physicalQualificationPassed: false`. A full
attempt repeats the preflight and creates a different lease:

```powershell
& $powershellExe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $entryPoint `
    -CandidateRoot $candidateRoot -ExpectedControllerCommit $controllerCommit `
    -EvidenceParent $evidenceParent -WorkParent $workParent -HostLabel 'lab-win11-01'
$pilotExitCode = $LASTEXITCODE
if ($pilotExitCode -ne 0) { throw "Physical qualification failed with exit $pilotExitCode; retain the attempt." }
```

Retain the dedicated process's terminal outcome line and actual exit status.
The full invocation uses `-ReleaseQualification -Accelerator whpx` on the
original `scripts/Invoke-EzVm010RealPortability.ps1` with additive telemetry.
There is no boot-only acceptance route, cached-fixture resume or reduced marker
set. An incomplete attempt must be diagnosed against its exact recorded source;
a corrected source requires a new immutable candidate and a new cold attempt.

### Owner-authorized completion without an overall timeout

For the replacement physical attempt, append **`-NoOverallTimeout` to both
dedicated invocations above**, including `-PreflightOnly`. This creates no native
execution or terminal timer. The same explicit policy is passed to the inner
controller and receipt validator; a receipt cannot opt itself into the exception.
Both receipts and the start record contain `overallTimeoutDisabled: true`, with
zero target, hard-wall and controller-budget fields meaning disabled, rather
than a large finite deadline. Elapsed time is still measured and retained.

The existing 120/150-second ACL probe limits, bounded Git and output operations,
and original base-build, READY and shutdown limits remain. Failed assertions,
process exits, output overflow, incomplete telemetry, changed source, cancelled
execution, unresolved owned processes and failed fixture removal still fail.
Job handles retain kill-on-close and disallow breakaway. A successful long run
under this policy must be labelled with that policy; it does not demonstrate
meeting the previous 60-minute performance target or a 90-minute operational wall.
Do not use the old controller checkpoint for this switch: use the newly reviewed
public commit containing the exception and keep its sources immutable.

## Deadline, containment and cleanup

In the default bounded policy, the 60-minute target measures the whole dedicated supervisor invocation, including
bootstrap, source checks, the synthetic preflight, full scenario, shutdown,
source revalidation and final evidence I/O. UTC timestamps accompany monotonic
elapsed seconds. The supervisor stops its exact controller Job at 5,340 seconds,
allows bounded observation of termination through 5,390 seconds and has a native
terminal watchdog at 5,400 seconds. Bootstrap before watchdog creation is charged
to the same clock and reduces the remaining budget. The controller has its own
shorter execution budget that reserves time for fixture disposal and evidence.
A default bounded run beyond 3,600 seconds cannot pass even if it finishes before the 90-minute
wall. The explicit owner-authorized `-NoOverallTimeout` policy instead has no
whole-invocation cutoff or elapsed-time rejection; its receipts record that exception.

Each child is created suspended, assigned to a Windows Job and then resumed.
Jobs prevent breakaway and have kill-on-close semantics; nested jobs contain the
full controller and qualification descendants. Cleanup acts on held native Job
and process handles. It never discovers ownership by process name or a reused
numeric PID. Separate evidence is required for child exit, zero active owned Job
processes, valid fixture ownership and successful fixture removal.

The child receives an explicit environment with Windows runtime paths and its
owned temporary directory. Each owned PowerShell child starts through the tracked
`Pilot.PowerShellEntry.ps1`, which sets that process's effective `PSModulePath` to
its own `PSHOME/Modules` before command autoload. It then invokes the original
target file with structured named parameters and preserves its exit behavior.
The EzVM module is imported by the pinned candidate's explicit path. Inherited
module paths are also excluded from the native environment; omission alone did
not prevent the observed Windows command-loading stall.

The dedicated outer supervisor initializes the same inbox module path only
after checking its actual `-NoProfile -NonInteractive -File` invocation using
BCL operations. The existing compiled invocation guard still gates the native
watchdog. Accidental dot-sourcing or invocation from an interactive or `-Command`
host is refused before any module-path change or timer is armed. These settings
belong to the dedicated processes and do not change user or machine settings.

After descendants have exited, normal controller cleanup verifies its unique
lease and successful exclusive fixture creation, then inventories only that
lease's exact fixture. A planned path alone is not ownership: a pre-existing or racing
directory that the attempt refused remains untouched. Reparse points, junctions,
hardlinks, a modified lease or unknown ownership refuse deletion. Unrelated
directories and sentinel files survive. A forced controller stop cannot safely
reconstruct the inner ownership state, so the outer supervisor quarantines the
private attempt and records failure. It does not guess which retained fixtures
to delete. Such retained diagnostics or disks must not be reused; recovery needs
the recorded lease and positively established process/storage ownership.

The native timers provide an operational wall for ordinary blocking controller
calls, including Git, CIM, hashing and evidence I/O. Windows scheduling and kernel
behavior are not a hard real-time guarantee. An absent completion record, missing
terminal marker or unconfirmed process exit is a failed/incomplete attempt; it
cannot be interpreted as successful cleanup merely because a timer fired.

## Acceptance and evidence

`RUNLOC_WHPX_SUPERVISOR_STARTED` identifies a fresh outer attempt. Its
`supervisor-started.json` is deliberately incomplete. Acceptance requires all of:

- A complete `supervisor-receipt.json` and matching
  `supervisor-receipt-digest.json`, bound to the fresh outer lease and immutable
  controller/candidate identities.
- Exactly one terminal
  `RUNLOC_WHPX_SUPERVISOR_OUTCOME=pass; elapsedSeconds=<duration>` line, printed
  after receipt/digest I/O and evidence-handle closure, with finite elapsed time
  no greater than 3,600 seconds under the default bounded policy. The explicit
  `-NoOverallTimeout` policy has no elapsed-time rejection and must match the
  policy selected by the operator, controller and receipt validator. A
  `preflight-pass` line never qualifies a VM run.
- Actual dedicated supervisor exit code zero. A receipt's provisional `pass`
  cannot qualify an attempt if final I/O blocks, the terminal line is absent or
  late, or the process subsequently exits unsuccessfully.
- A fresh validated inner receipt: actual full harness exit zero, every one of
  the 24 original full-release/WHPX PASS markers exactly once within coherent
  start/completion boundaries, no cleanup/source-restoration failure token,
  complete telemetry, unchanged source, and verified normal owned disposal.

The inner controller independently inspects both qualification roots. Each must
contain all five expected stopped guest records with WHPX and a launch identity.
The prepared-base accelerator, pinned source image and observed QEMU/base hashes
must agree across roots and with the telemetry. The complete original scenario
assertions continue to establish READY, persistence, isolation, reset, transfer,
export/import, refusal and cold-relocation behavior. A marker alone cannot replace
the process, source, identity and cleanup checks.

The output tree distinguishes publishable allowlisted evidence from private
diagnostics:

| Artifact | Purpose and publication |
|---|---|
| Outer `supervisor-receipt.json` and digest | Allowlisted result, deadline, process, source and inner-receipt binding. Publish together with terminal outcome and actual exit evidence. |
| Inner `receipt.json` and digest | Allowlisted phase observations, all markers, source/tool/image/host identities, exit and cleanup evidence. The inner lease lives below the outer `private/attempts` directory; select only these named files. |
| Inner `telemetry-events.json` | Allowlisted operation spans, image/tool identities and digest counters; its hash is bound by the inner receipt. |
| `lease.json`, `active.lock`, raw logs, raw telemetry and failure details | Private ownership or diagnostic material. May contain local paths or guest output. Do not publish or upload the enclosing attempt directory. |
| Retained fixture after failure | Private quarantined disks and runtime metadata. Do not publish, reuse or delete without establishing exact ownership. |

Raw logs are private, create-only and size bounded; the public event conversion
uses fixed names and value vocabularies rather than string-based redaction.
Telemetry records nested operations. Their durations and digest counters are
inclusive, so summing parent and child totals double-counts work. Use the root
`full-release` digest counters for totals and disjoint spans for comparisons.
Nested failure events are expected in original refusal tests; the root terminal
event, original assertions, actual exit and cleanup determine scenario success.

## Offline software checks

The focused suite uses synthetic repositories, files, ACL probes and short-lived
processes. It never starts a VM, downloads an image or uses a live credential:

```powershell
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File poc\windows-whpx\Test-Pilot.ps1
pwsh.exe -NoLogo -NoProfile -NonInteractive -File poc\windows-whpx\Test-Pilot.ps1
```

The repository CI pins PowerShell 7.6.6 for the second Windows lane. The main
suite also invokes `Test-Supervisor.ps1`. Tests cover source flags and filters,
dirty/staged/wrong source, stale and malformed receipts, failed exits despite
PASS text, missing markers, identity/accelerator mismatch, timing, bounded output,
descendant containment and refusal to remove unrelated or linked fixtures.
Non-Windows execution runs the portable synthetic checks and explicitly skips
the native Windows groups; those skips are neither Windows nor physical evidence.

Run the existing repository checks from the repository root as well:

```text
python scripts/check_repository.py
python -m unittest discover -s tests -p "test_*.py"
```

Keep the Runloc PR draft and issue #21 open until exact-head software checks,
review and the required complete cold physical WHPX evidence all satisfy the
binding contract. The next runner-registration and migration issues retain their
own dependency gates.
