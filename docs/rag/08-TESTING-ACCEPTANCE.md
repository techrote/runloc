# 08 — Tests, CI and issue acceptance

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

See [performance](09-METRICS-PERFORMANCE.md), [release](10-RELEASE-OPERATIONS.md).
