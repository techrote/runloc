# CI-POC-001 implementation and qualification checkpoint

## Acceptance status

**The reviewed software checkpoint passed; physical acceptance remains incomplete.**

This checkpoint belongs to [Runloc issue #21](https://github.com/techrote/runloc/issues/21).
The [binding PoC contract](WINDOWS-WHPX-CI-POC.md) records the owner's temporary
hosted-TCG scheduling exception; the full physical acceptance remains required.
The previous checkpoint was produced in a Linux cloud session without a physical
host. A native Windows 11 host is now connected. Its first exact-source preflight
passed, but Windows force-restarted the first full attempt before completion.
There is no completed receipt, numeric final exit or normal cleanup proof for
that attempt. Code, mocked results, diagnostic probes and hosted TCG cannot
satisfy the required complete cold physical run.

The standalone helper is under `poc/windows-whpx/`. It is an invocation and
evidence boundary for the existing EzVM scenario. RUNLOC-001 through RUNLOC-019,
CI-POC-002 runner registration and CI-POC-003 gate/fallback migration are outside
this change. CI-POC-001 remains open until every full-run and timing clause passes.

## Reconciled public upstream work

| Work | Exact observed source | Disposition and evidence |
|---|---|---|
| [EzVM #43](https://github.com/techrote/ezvm/pull/43), GitHub-hosted migration | `9f9e4f5762cd6251249b46c093039a4ef0e985fe` | Full original TCG release and core Windows checks passed. Independently reviewed; merged as `2f79e6b836a4592acfd6015bee58177fb15e3022`. |
| [EzVM #45](https://github.com/techrote/ezvm/pull/45), captured-start/lifecycle work | `8d4bacbe74e8c4d83d3cec9845e8a6026c62fd46` | Open. Core/DASH software checks passed, but full release failed on fresh-clone authenticated READY. Not imported or merged to advance this PoC. |
| [EzVM #46](https://github.com/techrote/ezvm/pull/46), explicit accelerator/pilot | Original `26c61967e91a008082ebc197f16dd94b943ad27c`; reviewed integrated candidate `59eee784b8016178c5589dea32cf2c9e72b942bd` | Draft. Original assertions preserved with additive bounded telemetry, public ACL repair and the temporary TCG exception. Use the Runloc supervisor for acceptance. Its original hosted READY failure remains retained below. |
| [EzVM #47](https://github.com/techrote/ezvm/issues/47) / [PR #48](https://github.com/techrote/ezvm/pull/48), private owner/DACL repair | Final head `d5fdebf2d759ee44e2ac4c604ffc2116c75cf740`; merged as `7b829f8352a9fa30c965e57386965767c5969e0d` | Exact-head repository, Windows core, standard-user ACL and DASH checks passed. The owner explicitly deferred only full hosted TCG. This software prerequisite does not close Runloc #21. |

The routine merge of #43 followed a four-file diff review, exact-head check
inspection, current-main reconciliation and an independent agent review. The
runner selectors, names and matching RAG changed; qualification assertions,
commands, triggers, permissions and deadlines were preserved. No branch-policy
change or administrator override was used.

The resulting main's [post-merge checks](https://github.com/techrote/ezvm/actions/runs/39049933237)
passed the repository contract and both Windows PowerShell 5.1 / pinned 7.6.6
control-plane suites. The prior complete exact-source release result remains
the migration's release evidence; no duplicate full workload was dispatched.

## Original attempts retained

The [allowlisted original-job observations](evidence/upstream-original-jobs.json)
retain source/job identities, actual phase-marker timestamps, completion markers
and decoded-log digests. These retrospective UTC observations are not new
physical pilot receipts or monotonic measurements. Raw logs remain on GitHub.

| Attempt | Evidence | Actual conclusion |
|---|---|---|
| Original cancelled hosted run | [Job 117367136257](https://github.com/techrote/ezvm/actions/runs/39022570303/job/117367136257) | Cancelled near three hours; incomplete and not a speed baseline. |
| First documented clean local pilot | [PR #46 contract at `26c6196`](https://github.com/techrote/ezvm/blob/26c61967e91a008082ebc197f16dd94b943ad27c/docs/CI-QUALIFICATION-COMPARISON.md) | Stopped after 422.83 seconds in image checks, before a qualification guest. Exact synthetic ACL failure was independently reproduced. Historical report, not a run performed in this session. |
| Corrected exact ACL preflight | [PR #46](https://github.com/techrote/ezvm/pull/46) | Blocked after 0.62 seconds, exit 2, `vmQualificationStarted=false`. No WHPX measurement. Historical report, not a run performed here. |
| Passing #43 hosted TCG release | [Job 117229236374](https://github.com/techrote/ezvm/actions/runs/38977149122/job/117229236374) | All 23 original TCG release PASS markers and successful source restoration. Approximately 179.24 minutes from scenario start to completion. This is a completed TCG workload observation, not WHPX evidence. |
| Failing #45 hosted release | [Job 117254507101](https://github.com/techrote/ezvm/actions/runs/38985066027/job/117254507101) | Fresh-clone authenticated READY timed out; final SSH evidence reported a child that exited without drained output streams. Graceful cleanup remained STOPPING. |
| Failing original #46 hosted release | [Job 117425241318](https://github.com/techrote/ezvm/actions/runs/39042709996/job/117425241318) | Source-restart authenticated READY timed out; final SSH evidence was a banner-exchange timeout. Graceful cleanup remained STOPPING. |

The last two failures do not establish an ACL root cause, nor prove that importing
#45 would repair #46. Any reproduced subsequent READY/pipe/cleanup blocker needs
its own narrow diagnosis against the immutable tested candidate. Failed attempts
are retained and corrections are appended; they are not relabelled as PASS.

The first two PR #48 standard-user fixture attempts stopped before the actual ACL
regression. At `01e673ac951a0a46a54ec1fd601ae2944026a08c`, the encoded setup
command exceeded the native credentialed-process command-line limit. At
`d49647dd817bb5c4bf7d86da1b9ab4dcbf52f99a`, the short script launch succeeded,
but application discovery combined three Git paths into one invalid executable.
Its child exit code was also unavailable through the original process object.
Both failed lanes retained diagnostics and removed their temporary accounts;
failed fixture directories were quarantined for disposable-host teardown.
These are launcher failures, not the required historical ACL reproductions.
The [second attempt](https://github.com/techrote/ezvm/actions/runs/39051034110)
retains both PowerShell artifacts. The same source passed the ordinary
[Windows repository and control-plane checks](https://github.com/techrote/ezvm/actions/runs/39051034115)
and [both DASH replay lanes](https://github.com/techrote/ezvm/actions/runs/39051034101).

## Proven standard-user private-DACL correction

At public `b370b78ce667b03368e859f40527b4280e438ff8`, tree
`0a590498574b3f9a056da1c88eb3c8c8acc011ad`, both actual ordinary-user lanes
completed **358 PASS / 0 FAIL / 0 SKIP**. Four retained controls reproduced the
expected `SeSecurityPrivilege` failure on baseline
`d5265c804d0d8494d8171482a85aca563b181e05`; all four passed on the candidate.
Six launcher regressions also passed. Both receipts prove a non-administrator
token with no special privileges, unchanged source, numeric child exit zero,
and removal of the owned temporary account and fixture.

| Actual lane | Evidence | Receipt duration |
|---|---|---|
| Windows PowerShell 5.1.20348.5622 | [Job 117453492279](https://github.com/techrote/ezvm/actions/runs/39052413893/job/117453492279) | 288.759272 seconds |
| PowerShell 7.6.6 | [Job 117453492134](https://github.com/techrote/ezvm/actions/runs/39052413893/job/117453492134) | 212.9012244 seconds |

The [allowlisted receipts and independent audit](evidence/private-dacl-regression.json)
include exact source/baseline identities, artifact/log SHA256 values, native
token observations, literal case counts and cleanup. Both downloaded ZIPs match
GitHub's advertised hashes. These times measure the ACL qualification, not a VM
workload or WHPX performance. All applicable checks also passed on final head
`d5fdebf2d759ee44e2ac4c604ffc2116c75cf740`, whose product, fixture and test files
are unchanged from the proven source.

The #48 merge's tree is exactly `2aa3170d8ba0a60ae98bb07803f63d9c04d41de0`.
Its actual post-merge [repository and both Windows core lanes](https://github.com/techrote/ezvm/actions/runs/39054219143),
[both standard-user ACL lanes](https://github.com/techrote/ezvm/actions/runs/39054219124)
and [both DASH replay lanes](https://github.com/techrote/ezvm/actions/runs/39054219122)
all passed. EzVM #47 is closed; Runloc #21 retains its separate physical gate.

## Temporary full hosted TCG deferral

On **2026-10-17**, the owner explicitly requested postponing the approximately
three-hour automatic TCG run until the end of CI-PoC. The reviewed change is
public [d5fdebf](https://github.com/techrote/ezvm/commit/d5fdebf2d759ee44e2ac4c604ffc2116c75cf740)
and included in the #48 merge. It changes only the full-job scheduling condition
for same-repository `ci-poc-*` and `ezvm-ci-whpx-pilot` PR heads, adds a visible
deferral notice and records the temporary AGENTS/RAG exception. Manual dispatch,
all other checks and physical WHPX acceptance remain available or required as
documented in the [binding exception](WINDOWS-WHPX-CI-POC.md#owner-authorized-temporary-hosted-tcg-deferral).

The [exact requested run](https://github.com/techrote/ezvm/actions/runs/39052413967/job/117453709701)
was observed **cancelled** after the replacement used the existing concurrency
group. The [replacement full job](https://github.com/techrote/ezvm/actions/runs/39053611174/job/117457228894)
is **skipped**; its [notice](https://github.com/techrote/ezvm/actions/runs/39053611174/job/117457227613)
completed successfully. TCG remains unmeasured; neither cancellation nor a green
notice is a qualification PASS. Original failed runs above retain their findings.

[CI-POC-003 / #23](https://github.com/techrote/runloc/issues/23) now explicitly
requires removing the temporary exception or replacing it with the reviewed
qualified-WHPX/independent-hosted-fallback policy and proving hosted-only rollback
before closing. The temporary change does not implement that later CI gate.

## Why the standalone evidence boundary is needed

The original full harness performs the original image, base, concurrent guest,
SSH, restart, reset, clone/export/import, identity and cold-relocation assertions.
Its explicit-accelerator version checks both the prepared-base manifest and every
READY response against the requested accelerator. Those assertions remain intact.

The original pilot wrapper accepted only three marker predicates and lacked an
overall hard wall and independent descendant/fixture cleanup proof. The final
release PASS marker occurs before `finally`; finalization can report caught
graceful-cleanup or source-restoration errors. A new receipt must therefore reject
those errors even if earlier PASS text and a zero child exit are present.

The Runloc helper requires exact public source identities before and after the
run, all original completion markers, a fresh unique attempt, bounded owned
Windows Job containment and independent cleanup evidence. Its allowlisted public
receipt is distinct from private raw diagnostics. Detailed commands, current
candidate pins and actual test results will be recorded with the published PR.

Review also requires the actual tracked file bytes to match public Git blobs,
with narrowly permitted text newline normalization. Clean Git status alone is
insufficient because index flags or clean filters can conceal edits. Receipt
validation requires correctly typed booleans and finite times, a coherent marker
interval, unique expected tool identities and all expected stopped guest records.
An independently timed supervisor contains the controller as well as its children;
it must run in its own PowerShell process so its terminal deadline cannot close an
interactive owner shell.

## Windows compatibility regressions retained

The first public Runloc helper `9966a10f99427843aa690555216ec42ce078bf35`
failed its [Windows software lanes](https://github.com/techrote/runloc/actions/runs/39052753848).
Test teardown attempted to remove read-only Git objects and masked the primary
failure. Diagnostic successor `0138fe202d344acff9f4b5822dac66e1b124a6ff`
preserves the first failure and validates the complete owned test inventory before
clearing ordinary file attributes and deleting it. Its
[actual Windows logs](https://github.com/techrote/runloc/actions/runs/39053709996)
exposed the distinct source-parser and long-path failures below.

Windows PowerShell 5.1 selected the wrong Framework `String.Split` overload for
a scalar NUL separator plus options, leaving an empty source-index entry. The
explicit `char[]` overload preserves the required parsing semantics. A retained
Framework-overload regression reproduces the old result and verifies the new
form, including whitespace, control characters and empty inventories. Telemetry
line iterators are also explicitly disposed when negative parsing throws, so
failed validation cannot leave a Windows file handle open during cleanup.

The PS7 failure reached native file-link validation on a fixture path beyond
Windows' legacy limit. The [pinned archive and source-path audit](evidence/windows-path-budget.json)
measured the actual QEMU/extractor archives and immutable source definitions,
including long icon filenames, relocation, immutable-base and atomic temporary
paths. The original full harness needs a maximum fixture length of 44 UTF-16 code
units: the measured file suffix of 215 reaches 259; the directory reserve is 173.

The helper therefore uses a separate existing user-writable `WorkParent` and a
compact filename encoding all 128 lease bits, while retaining the full lease ID
and exact fixture mapping privately. It rejects insufficient work/evidence path
space before a controller, download or qualification fixture starts. The original
harness layout, assertions and host long-path policy remain unchanged. Creation
and cleanup require positive ownership; an existing or racing directory must
remain untouched. The creation latch is set only after exclusive creation succeeds;
cleanup also verifies a digest-bound creation receipt before inspecting an existing
fixture. An independent production-API probe changed from deleting a refused
sentinel directory to preserving it, and passed all four ownership cases. Missing
or incompletely persisted creation proof quarantines the attempt. The outer
supervisor independently checks the recorded external
fixture's absence and quarantines uncertain attempts.

The first integrated EzVM candidate `ef713d831bca1de02935f411f4e22b49102970e1`
also exposed one test-only Windows sharing error: both control-plane lanes and
the retained ordinary-user PS5 artifact reported **375 PASS / 1 FAIL / 0 SKIP**.
The [original evidence](evidence/integration-windows-regression.json) preserves
job/source identities and the failed fixture's quarantine. The repaired public
candidate `59eee784b8016178c5589dea32cf2c9e72b942bd` changes only the telemetry
test to finalize the failed session before reading its retained output, and adds
checks for stream disposal and both operation/full-release failure records.
Production telemetry sharing, full-release assertions and ACL code are unchanged.

### Native Windows child module-discovery correction

The corrected path/ownership source `477262786f040291e247d2d4e5b7b3436bf7bdae`
passed all 47 pilot and 17 supervisor groups under Windows PS7, with zero skips.
PS5 passed the preceding source, path and ACL controls but failed at its first
contained PowerShell child. The [retained Windows audit](evidence/runloc-windows-regressions.json)
preserves this red result, the missing suite summary and subsequent diagnostics.
The original process deadline and expected synthetic exit 9 were retained.

Diagnostic `3308de7d57e218152fdf4052b461ba54f4933ccf` established that the PS5
child entered its script and produced direct Console stdout, then stalled at
`Write-Output`. In the [same Windows job](https://github.com/techrote/runloc/actions/runs/39057706961/job/117468984055),
an otherwise identical child which set its own module path reached exit intent,
captured both expected lines and exited 9 in 0.323187 seconds. The baseline timed
out after 15.1642197 seconds with a clean forced Job stop. These are synthetic
software observations, not VM timing results.

The next production attempt, `dfbfb855d5971e071dd2c2a3921912fe9a0e1a9e`,
omitted inherited `PSModulePath` from the native child's environment so Windows
PowerShell constructs its defaults, as
[Microsoft documents for intermediate/native launches](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath?view=powershell-7.6#starting-windows-powershell-from-powershell-7).
The portable environment-factory regression changed from red to green, but the
[actual Windows lanes](https://github.com/techrote/runloc/actions/runs/39058333120)
both still failed the original contained-child test. Their reconstructed default
paths include CurrentUser and AllUsers; omitting the inherited variable did not
establish an effective inbox-only path. Both children captured direct stdout but
timed out at `Write-Output` after approximately 15.1 seconds. In those same jobs,
both controls that set their own process path to `PSHOME/Modules` reached the
expected exit 9 and both stdout records in approximately 0.33 seconds.

The retained audit includes the exact source, both red job/log identities and
the passing repository checks. It preserves the original failure and fixed
15/20-second deadlines. This evidence requires initialization inside each owned
PowerShell process before command autoload; removing a variable from the parent
environment alone is insufficient. Corrected exact-source Windows acceptance is
recorded separately after CI.

The revised startup boundary uses the tracked `Pilot.PowerShellEntry.ps1` for
the controller, exact ACL preflight and original full harness. Before autoload,
each dedicated process sets its effective module path to its own inbox modules.
The entry forwards structured named parameters and literal positional arguments
to the original target file; it preserves explicit exits, terminating failures
and normal return after a handled native failure. The candidate's harness bytes
and all qualification assertions remain unchanged.

The outer supervisor and child entry share a BCL-only invocation guard in
`Pilot.Bootstrap.ps1`. It refuses accidental direct calls or dot-sourcing before
changing the calling process's module path. The outer clock still starts first,
and its original compiled invocation guard remains mandatory before the native
watchdog is armed. Both startup files are included in the selected controller
pins and full tracked-source verification. Parent/user/machine module settings,
native process ownership, output capture and original deadlines are preserved.

### Corrected Windows software acceptance

Public controller `14e789abc9a965e3b60e995cf44cc7d63ddf78e6`, tree
`1ccd71e70291cb3138b0cf7f4a5082de0edfa19a`, completed both actual Windows
lanes. Each log records that exact checkout and tree, and every required native
group ran. The [retained audit](evidence/runloc-windows-regressions.json) appends
the green result while preserving all earlier failed attempts.

| Actual lane | Exact job | Reported result |
|---|---|---|
| Windows PowerShell 5.1 | [117476625053](https://github.com/techrote/runloc/actions/runs/39060272297/job/117476625053) | 53 pilot / 18 supervisor PASS; 0 skipped test groups |
| Pinned PowerShell 7.6.6 | [117476625156](https://github.com/techrote/runloc/actions/runs/39060272297/job/117476625156) | 53 pilot / 18 supervisor PASS; 0 skipped test groups |

The previously failing baseline reached `EXIT_INTENT`, captured both the direct
stdout line and original `Write-Output` marker, and exited with the expected 9.
Its recorded end time was 0.6541122 seconds under the PS5 parent and 0.7600862
under PS7. Both prove child exit, zero active owned processes, normal completion
without force or timeout, and no output overflow/read failure. The original
15/20-second bounds remain unchanged. These short synthetic observations are
not measurements of the full VM workload.

The poisoned-module control and all seven Windows pilot/two Windows supervisor
groups passed, including ACL preflight ordering, owned descendants, unrelated
sentinel survival, log bounds, nested Job watchdogs and terminal self-exit.
The new parameter/exit/caller-refusal regressions also ran in both lanes.
[Both repository jobs](https://github.com/techrote/runloc/actions/runs/39060272265)
passed the programme contract and all 21 Python cases. The workflows explicitly
record `PHYSICAL_WHPX_QUALIFICATION=NOT_RUN`; no VM qualification was dispatched.

## Frozen candidate software acceptance

The approved EzVM execution manifest names public
`59eee784b8016178c5589dea32cf2c9e72b942bd`, tree
`f609fa6aa429a9b78fa89ef763126d9ef023e8d0`. Its
[final ordinary-user Windows lanes](https://github.com/techrote/ezvm/actions/runs/39055025533)
each executed that exact head directly and completed **376 PASS / 0 FAIL / 0 SKIP**.
The [retained audit](evidence/final-candidate-windows.json) verifies both artifact
digests and literal counts, all four legacy/corrected ACL controls, all seven
telemetry cases, all six launcher cases, the ordinary token, unchanged source,
numeric child exit zero and successful account/fixture cleanup.

The [repository and both core checks](https://github.com/techrote/ezvm/actions/runs/39055025578)
also passed. Core executed GitHub PR-merge commit
`2f25017e7b7a2a60c6817a3a225b247450a98840`, whose tree is exactly the frozen
candidate's `f609fa6aa429a9b78fa89ef763126d9ef023e8d0`; both suites report 376/0/0.
[Both DASH checks](https://github.com/techrote/ezvm/actions/runs/39055025546)
passed. [Full hosted TCG](https://github.com/techrote/ezvm/actions/runs/39055025413)
is explicitly deferred under the owner's temporary exception.

The manifest's `executionApproved: true` approves this software source for the
physical attempt. It does not mean that the physical run passed, that the Runloc
helper is qualified solely by upstream tests, or that draft EzVM #46 is merged.

## Executed checks and review roles

Before implementation, the Runloc repository contract and all 21 existing Python
unit tests passed against main `256881866befa8dde246cc9c94d5d150e9569d70`.

The primary assistant coordinates implementation, source reconciliation and
publication. One delegated agent authors the EzVM ACL correction; a second
authors the Runloc helper. A third independently inspected the original public
source, actual failing/passing logs and #43's four-file diff. The ACL author also
implemented the outer supervisor and independently reviewed the inner controller;
the original audit agent implemented the additive telemetry and launcher repair.
The primary assistant reviewed the final production changes and integrated the
public sources. These are actual model-agent roles, not external human approval.

For the startup correction, the audit agent independently reviewed the shared
BCL guard, both entry points' side-effect ordering, source pins and caller-refusal
tests. The supervisor author independently reviewed the helper author's envelope,
target invocation and production routing, then compared actual adapter subprocess
results with direct `-File` behavior. The primary assistant reviewed and integrated
the combined production, test and operator changes.

The independent inner-controller review found a real native type mismatch:
Windows Job active-process counts are `UInt32`, while the initial receipt oracle
accepted only signed integers before serialization. The retained regression was
observed failing against the initial oracle, then passed after the two native
counters were explicitly accepted. String, boolean, floating and nonzero counts
remain failures.

Current local checks on Linux with PowerShell 7.6.6 passed all 46 pilot groups
and the separately reported 16 supervisor groups. Seven pilot and two supervisor
groups require Windows and are explicitly skipped locally. All PowerShell scripts
parsed and both native C# types compiled. The Runloc repository contract and all
21 Python tests passed after implementation. Actual Windows CI and physical
qualification are separate required evidence; no local skip satisfies them.

The startup regressions execute the real entry with ten explicit-exit, error and
normal-return cases, plus named switches, integer types, empty values and literal
quote/backtick/command-looking arguments. They reject malformed, oversized or
non-primitive envelopes and case-insensitive duplicate parameter names before
the target executes. Both entry points also have actual call/dot-source refusal
checks that preserve the existing process module path. Windows runs use the
production owned-process boundary for these children.

## Remaining gate

A supported physical standard-user Windows host must run the complete cold WHPX
scenario using the recorded clean immutable controller/candidate. It must return
zero, emit the full marker set, agree on accelerator, preserve tested source,
record the required identities/phases, and prove clean owned shutdown/disposal.
Under the default policy the complete run must meet the 60-minute target within
the 90-minute hard wall. The replacement attempt may instead use the later
owner-authorized `-NoOverallTimeout` policy described in the binding contract;
its actual elapsed time remains evidence, with no claim to the former target.
Only then may the Runloc PR pass this issue's physical merge gate. Later runner
registration and CI-gate work have their own trackers and are not started here.

## Connected physical attempt, reboot and replacement policy

The native Windows 11 ordinary-user host passed the exact synthetic preflight at
controller `36987dfed17e69efa078d4e7b97f0c78e9992ae8`, tree
`b2b9452b55771d276d78629fc738525d08f722c2`, against frozen EzVM
`59eee784b8016178c5589dea32cf2c9e72b942bd`, tree
`f609fa6aa429a9b78fa89ef763126d9ef023e8d0`, in **11.244 seconds**, exit **0**.
The separate full attempt `9c45639521084c37a102620ad568d827` was interrupted by
the owner's reported forced Windows restart. Its last telemetry reached
**1,466.400 seconds**, still in tiny-image operations, with two completion
markers. No final harness/supervisor exit, total elapsed time, completed receipt
or normal owned shutdown is inferred. The later boot boundary is observed;
the cause of the Windows restart is not diagnosed here.

[Interrupted attempt and verified recovery](evidence/physical-whpx-20261017-reboot-interrupted.json)
and [all retained partial phase events](evidence/physical-whpx-20261017-interrupted-telemetry.json)
preserve the failure. The original private records are unchanged. The old mutable
fixture was removed only after matching its lease and exclusive creation proof,
verifying the lease digest and reboot boundary, acquiring its exclusive lock,
finding no active process reference, and running the original safe disposal
routine. Private JSON/log diagnostics and the complete inventory remain retained.
No mutable guest or old receipt is reused.

The [rudimentary performance diagnostics](evidence/physical-whpx-20261017-performance-diagnostics.json)
used freshly verified immutable tools and a new 128 MiB synthetic disk:

| Observation | Measured result |
|---|---|
| Complete 3,384-file / 1,255,872,082-byte QEMU integrity scan | First scan 55.173 seconds; subsequent scans 15.338 / 16.297 seconds |
| Direct qemu-img version/create/info/read/write/check, including owned process startup | Approximately 0.1–0.24 seconds per call; every exit 0 |
| Halted one-CPU / 128 MiB q35 WHPX initialization, QMP exchange and normal quit | 0.657 seconds; exit 0; zero owned processes |

Tiny cached I/O is not a sustained-disk benchmark, and halted initialization is
not guest boot or full-release acceptance. The first diagnostic parser rejected
an asynchronous QMP event; that failed diagnostic is retained. The corrected
probe completed normally. No qualification or performance target is claimed
from either diagnostic. The interrupted attempt separately completed 67 full
payload validations averaging 21.029 seconds each, which identifies a substantial
control-path cost without permitting integrity checks to be skipped.

The owner then explicitly requested removal of the target/time limit/cutoff for
the replacement run. The new `-NoOverallTimeout` mode constructs no native
overall timers and removes whole-invocation elapsed-time rejection while keeping
all original operation limits and every non-timing gate. Its explicit expected
policy must match both receipts; zero policy fields mean disabled. Default
bounded behavior and watchdog negative controls remain. This exception does not
restart deferred hosted TCG, merge EzVM PR46 or implement CI-POC-002/003.

The implementation agent authored the exception and diagnostics. A separate
model agent independently reviewed the source, frozen-candidate linkage and
negative controls at Extra High reasoning; no material code issue was found.
Its documentation corrections were applied. These are model-agent roles, not
external human approval. Physical acceptance of the new controller remains
outstanding; the previous checkpoint's software results do not qualify changed
executable bytes.

The final local Windows PowerShell 5.1 run passed **56 pilot groups and 20
supervisor groups, with zero skipped platform groups**. Repository checks and
all 21 Python tests also pass. The first new supervisor fixture used an offset
UTC string rather than the required canonical `Z` string; the production UTC
guard correctly refused it. The original failed software log is retained and the
fixture was corrected, after which the complete unchanged guard suite passed.
Exact-head hosted PS5.1 and pinned PS7.6.6 checks remain required before execution
of the revised controller. They use synthetic processes and never start TCG.

## First no-overall-timeout preflight and narrow overload correction

Public controller `92d95a13c49786bac7477dec4331a71d53a6a521`, tree
`cfb7eb4406b857ab5fb5dd2023c588ef8d6af92f`, passed exact-head hosted Windows
PS5.1 and pinned PS7.6.6 software checks, each **56 pilot / 20 supervisor groups,
zero skipped platform groups**, plus both repository lanes. The subsequent real
preflight failed before the inner qualification lease or fixture: actual exit
**2**, outer elapsed **3.138 seconds**, zero active owned processes, no downloads
or VM. [The immutable failed preflight](evidence/physical-whpx-20261017-no-timeout-preflight-failure/index.json)
remains retained; it is not overwritten by the correction.

Windows PowerShell selects an integer overload for `Math.Min(integer, infinity)`
and rejects infinity before performing the clamp. The failure was reproduced
directly in the Git-wait calculation; the same overload existed in both bounded
output-drain calculations. Using explicit double operands fixes the binding
while retaining the actual finite 15-second Git and 3-second output limits.
New regressions exercise real Git source verification and both actual owned
child/supervisor output paths with an unbounded overall deadline. The original
timers, operation limits, source validation and cleanup assertions are preserved.
