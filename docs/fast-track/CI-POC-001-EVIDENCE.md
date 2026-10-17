# CI-POC-001 implementation and qualification checkpoint

## Acceptance status

**Implementation in progress; physical acceptance is held.**

This checkpoint belongs to [Runloc issue #21](https://github.com/techrote/runloc/issues/21).
The [binding PoC contract](WINDOWS-WHPX-CI-POC.md) and original issue acceptance
remain unchanged. This cloud session has Linux execution and GitHub access; no
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
| [EzVM #46](https://github.com/techrote/ezvm/pull/46), explicit accelerator/pilot | Original `26c61967e91a008082ebc197f16dd94b943ad27c` | Draft. Reusable original full assertions; original pilot lacks the new Runloc ownership/evidence boundary. Its full hosted run failed on source-restart READY. |
| [EzVM #47](https://github.com/techrote/ezvm/issues/47) / [PR #48](https://github.com/techrote/ezvm/pull/48), private owner/DACL repair | Published draft; standard-user fixture corrections under test | Narrow software prerequisite, with exact-source standard-user legacy-red/candidate-green regression requirements. Closing it cannot close Runloc #21. |

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

Current local checks on Linux with PowerShell 7.6.6 passed all 33 pilot groups
and the separately reported 14 supervisor groups. Six pilot and two supervisor
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
