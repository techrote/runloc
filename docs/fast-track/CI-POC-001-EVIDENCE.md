# CI-POC-001 implementation and qualification checkpoint

## Acceptance status

**Implementation in progress; physical acceptance is held.**

This checkpoint belongs to [Runloc issue #21](https://github.com/techrote/runloc/issues/21).
The [binding PoC contract](WINDOWS-WHPX-CI-POC.md) records the owner's temporary
hosted-TCG scheduling exception; the full physical acceptance remains required.
This cloud session has Linux execution and GitHub access; no
supported physical Windows/WHPX host is connected. Code, mocked results and
hosted TCG cannot satisfy the required complete cold physical run.

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

The independent inner-controller review found a real native type mismatch:
Windows Job active-process counts are `UInt32`, while the initial receipt oracle
accepted only signed integers before serialization. The retained regression was
observed failing against the initial oracle, then passed after the two native
counters were explicitly accepted. String, boolean, floating and nonzero counts
remain failures.

Current local checks on Linux with PowerShell 7.6.6 passed all 41 pilot groups
and the separately reported 15 supervisor groups. Six pilot and two supervisor
groups require Windows and are explicitly skipped locally. All PowerShell scripts
parsed and both native C# types compiled. The Runloc repository contract and all
21 Python tests passed after implementation. Actual Windows CI and physical
qualification are separate required evidence; no local skip satisfies them.

## Remaining gate

A supported physical standard-user Windows host must run the complete cold WHPX
scenario using the recorded clean immutable controller/candidate. It must return
zero, emit the full marker set, agree on accelerator, preserve tested source,
record the required identities/phases, and prove clean owned shutdown/disposal.
The complete run must meet the 60-minute target within the 90-minute hard wall.
Only then may the Runloc PR pass this issue's physical merge gate. Later runner
registration and CI-gate work have their own trackers and are not started here.
