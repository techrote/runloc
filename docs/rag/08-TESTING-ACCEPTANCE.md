# 08 — Tests, CI and issue acceptance

CI-POC-002 adds [offline runner controls](../../poc/windows-whpx/Test-Runner.ps1)
to both pinned Windows helper lanes. They do not register a runner or qualify a
physical run. Acceptance separately requires the exact approved Actions
run/job/runner association, full supervised six-CPU WHPX evidence, old-runner
second-job refusal, fresh-registration reuse of the same backing environment,
and real failed/no-job deregistration and owned material cleanup. The owner's
current `-NoOverallTimeout` policy removes Runloc's overall target/wall for this
execution; original operation limits and truthful GitHub service limits remain.

## Test layers

1. Fast deterministic unit and process-adapter tests on hosted Windows and Ubuntu:
   input/schema/state/dispatch/capacity/evidence invariants, temporary roots with
   spaces, fake clocks/APIs/processes and real lightweight child-process fixtures.
2. Windows-specific real local process/ACL containment tests in hosted Windows CI,
   without QEMU boots, credentials, feature changes or administrator requirements.
3. Small optional qemu-img/synthetic storage checks with locked tools, separate from
   ordinary source CI and bounded independently from full VM qualification.
4. Opt-in physical Windows/WHPX qualification on approved hardware, and an approved
   GitHub test repository for actual one-job registration/run/disposal evidence.

The planning bootstrap provides `python scripts/check_repository.py` and validator
unit tests. RUNLOC-001 adds the product package, `python scripts/check.py`, executable
fixture conventions and stable required check names. Use Python 3.12 and stdlib
unittest first. Pin any added test dependency. Tests must execute the intended source,
not a stale installed package. Check subprocess exit, not a pipe's final command.

Normal PR CI never needs live credentials or a hypervisor. Required hosted checks:
repository/programme contract and unit/process Windows/Ubuntu once001 adds them.
New docs/source paths must not force full VM acceptance on every PR. Path filters
may reduce work only with a stable required-status design that cannot leave checks
missing or bypass runtime changes. Set finite job timeouts and read-only permissions;
pin actions to reviewed full SHAs and document intentional capability skips.

## Evidence rules

Issue acceptance includes its observable clauses, real retained regression tests,
exact head/source identity, clean intended diff, test logs/results and updated RAG.
No acceptance from launch/online/READY alone, pass counts without assertions,
all-skipped/empty suites, model prose or a marker with failed exit. Guest success
text does not prove GitHub conclusion or host disposal.

Real qualification records controller commit, candidate/job/definition identities,
tool/image/runner digests, requested and observed accelerator, host/guest profile,
start/end/deadlines, GitHub run/job IDs and conclusion, exact registration removal,
QEMU exit and overlay/seed disposal. Missing API or physical evidence remains
incomplete. Keep original red/green outputs and append corrections; no rewriting
historical findings or attribution. Public artifacts contain only redacted summaries
and bounded allowed logs, never runtime disks, credentials or raw JIT configuration.

Hardware/API-gated issues remain open until real evidence exists. If unavailable,
produce the implementation PR with precise limitations; do not relabel mocked
coverage as physical PASS. Foundational issues may merge without physical gates
they do not own. The release gate requires them later.

## PR and post-merge gate

Follow [AGENTS](../../AGENTS.md). Check all actual required head statuses and resolved
review threads; never count a skipped failing check as green, use admin bypass or
merge with a known relevant failure. Monitor about every120seconds. Source changes
after green tests need changed-tree tests; unchanged green VM qualification is
reused for docs-only changes with an explicit tree identity comparison. Required
post-merge checks must still be observed. A full test need not rerun just to repair
prose or metadata, but claimed evidence must identify the tree actually tested.

V0.1 physical gate: at least 3 successive independent clean job leases with distinct
runner/disk identities and no contamination, a failed job with complete cleanup,
and a cold-controller restart recovery. Performance targets and trials are defined
before measurement by012; release cannot claim fast/equivalent behavior without it.
Follow-ons may legitimately end in a reviewed no-go decision when their issue says so.

## CI-POC-001 software and physical evidence

The owner authorized a temporary automatic hosted-TCG scheduling deferral on
2026-10-17 for the scoped EzVM CI-PoC PRs. See the
[binding exception](../fast-track/WINDOWS-WHPX-CI-POC.md#owner-authorized-temporary-hosted-tcg-deferral).
It leaves the software/ACL checks and physical acceptance below required, records
TCG as SKIP/unmeasured, and expires when CI-POC-003 restores or replaces the policy
with its reviewed gate and independent hosted fallback. Prior failures remain
visible. A successful deferral notice is not a successful release qualification.

The standalone Windows helper has a separate credential-free hosted workflow,
`Windows WHPX PoC software contracts`, on `windows-2022`. It runs the real helper
contracts under Windows PowerShell 5.1 and hash-pinned official PowerShell 7.6.6.
Lightweight native process, private ACL, ownership and link fixtures exercise
the Windows-specific boundary. They perform no QEMU/WHPX boot or runner
registration. Existing Windows/Ubuntu programme and Python unit checks remain
required. Linux PowerShell results supplement Windows results and report
Windows-only capabilities explicitly.

The physical operator must use the published exact controller and EzVM candidate,
first run the exact synthetic preflight, then run one complete cold original
release/portability scenario. Evidence needs all 24 original WHPX PASS markers,
explicit requested/observed accelerator agreement, exit zero, immutable source,
tool/image/host identities, phase timing and independently observed owned cleanup.
Negative controls reject missing/conflicting markers, nonzero exit despite PASS,
stale receipts, wrong source/ownership, failed preflight and redirected paths.

The target is at most 60 minutes for a complete run. The 90-minute hard wall
includes a bounded cleanup reserve; neither cancellation nor timeout qualifies.
An otherwise successful run above the target keeps CI-POC-001 open. A preflight
pass, synthetic containment test or hosted TCG result does not establish physical
WHPX correctness or performance. Details and actual upstream dispositions are
recorded in the [checkpoint](../fast-track/CI-POC-001-EVIDENCE.md).

The later owner-authorized replacement attempt may explicitly select
`-NoOverallTimeout`, as recorded in the [binding exception](../fast-track/WINDOWS-WHPX-CI-POC.md#later-owner-instruction-for-the-replacement-physical-attempt).
Both the 60-minute whole-invocation target and native 90-minute timer are disabled
only for that matching operator/controller/receipt policy. Original per-operation
limits and all non-timing qualification gates remain. Default bounded tests
continue to enforce the original deadlines; additional controls must reject
cross-policy receipts and preserve failures in the no-overall-timeout mode.

See [performance](09-METRICS-PERFORMANCE.md), [release](10-RELEASE-OPERATIONS.md).

## CI-POC-002 retained acceptance

The [physical and lifecycle receipt](../fast-track/CI-POC-002-EVIDENCE.md#successful-full-qualification-and-lifecycle-closeout--18-october-2026)
binds the full six-vCPU WHPX Actions job to its exact host/job controller,
candidate and workflow commits. All24markers,8authenticated READY responses,
8CPU proofs, numeric zero exits, source preservation, nested fixture cleanup,
process emptiness and exact registration absence passed. A second job targeting
the used label remained unassigned; a fresh registration then passed a bounded
reuse probe on the same backing environment. A fresh no-job attempt truthfully
failed and cleaned up. The complete run took7522.7706465seconds under the owner's
explicit NoOverallTimeout policy; no former60minute performance gate is claimed.

Public receipt bytes and their digests are preserved without Git newline
conversion. Final monitoring uses retained receipt counts after disposal;
observations and final host cleanup remain separate facts. Monitor-only and
synthetic-test visibility repairs do not alter the physically executed payload.
CI-POC-003 retains gate/fallback/TCG-policy migration and performance work.

CI-POC-003's opt-in guest diagnostics are separate from acceptance. The
[diagnostic scenarios](../../poc/windows-whpx/QUALIFICATION-GATE.md) distinguish
basic cold cloning from source restart, export/import and source-reset ordering.
Their exact-source, owned-process and failed-fixture forensic controls remain
required; neither successful guest boots nor their diagnostic receipts grant
full qualification or clear a failed comparison. Synthetic persistence contents
are asserted through authenticated commands with actual numeric exits.

Hosted failure reduction must recognize the original harness's bounded
`BASE_LOG_TAIL`/`BASE_LOG_LINE` sections as well as instance serial tails. Only
exact base-stage UUID headers establish diagnostic context. JSON failure messages
and serial tails reduce to closed codes and bounded numeric facts; raw paths,
prose and seed material are not published. Stripping a diagnostic prefix is local
to the reducer and must never expose guest success markers to the host oracle.
Negative controls cover absent/stale/wrong contexts, nested headers, large lines,
spoofed PASS text, redaction and missing versus observed/truncated capture.

The opt-in `full-forensic` local diagnostic runs the unchanged complete original
workload after exact ACL preflight, under private native ownership. Six CPUs,
original memory/assertions/per-operation limits, exact sources before/after,
numeric child status, phase telemetry and cleanup remain required. Only that
explicit mode uses the owner's NoOverallTimeout policy; focused modes remain
bounded. Failed private fixtures are forensic quarantine, inspected only after
positive process emptiness. Direct-host diagnostic execution has no JIT/Actions
association and can never clear the source gate or grant CI-POC003 acceptance.
Every controller rejects a timed-out or cancelled ACL preflight even when its
child races to a natural exit0 before cleanup. Timeout/cancellation facts remain
in the receipt; a PASS line and zero exit cannot override either condition.
