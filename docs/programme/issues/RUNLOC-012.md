# RUNLOC-012 — Run the clean timed WHPX pilot and publish a go/no-go assessment

Stage: **v0.1**. Planning status: **planned**. This issue is not implemented by publication of the programme.

## Dependencies and prerequisites

Depends on: [RUNLOC-005](https://github.com/techrote/runloc/issues/5), [RUNLOC-010](https://github.com/techrote/runloc/issues/10), [RUNLOC-011](https://github.com/techrote/runloc/issues/11)

Approved Windows/WHPX hardware, accepted image/adapters, configured test-repository auth and numerical targets written before measurement. If unavailable publish a blocked report and keep this issue open.

Confirm dependency PRs are accepted on current main before coding. Follow-on issues do not block v0.1.

## Autonomous execution prompt

Implement **RUNLOC-012** end to end in `techrote/runloc`. Fetch current main; read this complete live issue and every comment, dependency result, overlapping PR and the linked instructions below. Use an isolated `runloc-012-short-name` branch. The owner authorizes the ordinary implementation, tests, PR and merge cycle under these contracts; routine confirmation is unnecessary. Do not start a later issue or deploy unrelated infrastructure.

The scope, observable acceptance and tests below are binding. Inspect existing code first and preserve already accepted work. Add meaningful retained regressions and exact-source checks; use synthetic credentials and temporary assets. Update affected RAG contracts with implementation. Review and improve the change before opening the PR; record the actual reviewer/author roles without claiming independence from self-review.

## Required instructions and RAG material

- [AGENTS.md](https://github.com/techrote/runloc/blob/main/AGENTS.md)
- [README.md](https://github.com/techrote/runloc/blob/main/README.md)
- [docs/programme/IMPLEMENTATION-PROGRAMME.md](https://github.com/techrote/runloc/blob/main/docs/programme/IMPLEMENTATION-PROGRAMME.md)
- [docs/programme/PLAN-REVIEW.md](https://github.com/techrote/runloc/blob/main/docs/programme/PLAN-REVIEW.md)
- [docs/rag/README.md](https://github.com/techrote/runloc/blob/main/docs/rag/README.md)
- [docs/rag/00-SCOPE.md](https://github.com/techrote/runloc/blob/main/docs/rag/00-SCOPE.md)
- [docs/rag/08-TESTING-ACCEPTANCE.md](https://github.com/techrote/runloc/blob/main/docs/rag/08-TESTING-ACCEPTANCE.md)
- [docs/rag/11-SOURCES.md](https://github.com/techrote/runloc/blob/main/docs/rag/11-SOURCES.md)
- [docs/rag/09-METRICS-PERFORMANCE.md](https://github.com/techrote/runloc/blob/main/docs/rag/09-METRICS-PERFORMANCE.md)
- [docs/rag/02-HOST-QEMU.md](https://github.com/techrote/runloc/blob/main/docs/rag/02-HOST-QEMU.md)
- [docs/research/EZVM-FIELD-NOTES.md](https://github.com/techrote/runloc/blob/main/docs/research/EZVM-FIELD-NOTES.md)

## Scope to deliver

- Commit a qualification plan with workload/parity assertions, resource/cache/network conditions and numerical acceptance targets before any timed trial.
- Run clean cold/warm Windows/WHPX Linux-job trials with independent hosted Linux reference and complete failure/disposal evidence.
- Analyze phase costs and measured bottlenecks, repair small proved defects and publish reproducible receipts plus an explicit qualification decision.

## Observable acceptance criteria

- At least 3 trials per declared cold/warm mode use fresh leases and exact controller/candidate/definition/input identities, with all samples retained.
- Actual WHPX execution, GitHub job assertions, registration disposition and local disposal are independently observed; detection/configured accel is insufficient.
- Report median/range and cold/warm phase breakdown, not unsupported p95 or borrowed EzVM Windows timings.
- Zero false success/leaked/second-job runners,3/3 clean leases per accepted mode, failure cleanup and predeclared timing/resource targets determine go/no-go.
- A no-go is reported honestly and keeps physical product/release gates open until repaired or explicitly revised; no permanent runner registration to disguise failure.

## Required implementation/testing work

- Negative-control checks invalidate incomplete logs, wrong source/recipe/accelerator, mismatched guest OS or failed workload despite fast wall time.
- Replay receipts through assessment code and compare against known pass/fail boundary fixtures.
- Full approved physical/API pilot, including standard-user exact ACL preflight, verified source cleanliness and actual complete end markers.

Also run `python scripts/check_repository.py` and `python -m unittest discover -s tests -p "test_*.py"`. From RUNLOC-001 onward run the consolidated `python scripts/check.py` and the issue's focused tests. All commands must target the intended checkout. Normal PR checks must require no VM/API credentials; separate physical/live acceptance is required only where specified and cannot be replaced by a mocked or all-skipped pass.

## Excluded scope

No self-granted privileges, host setting changes, owner-patch copy, Windows nested-WHPX claim or required-gate promotion.

## PR, automated checks and autonomous merge

Commit only clean intended source/tests/docs. Push a PR containing `Closes #<this issue number>`, a concise behavior summary, actual test/evidence links, limitations and RAG updates. Do not close this issue through a partial implementation. Inspect final diff and resolve material review findings. Wait for **all actual required automated checks on the exact PR head**, with about 120-second polling intervals. Fix relevant failures; do not disable checks or merge known-red work.

When dependencies and every acceptance clause are satisfied, required checks are green, review threads are resolved and no owner hold exists, squash-merge using the exact expected head. Do not use admin overrides or weaken branch protection. Verify the resulting main and post-merge checks, then add a factual completion comment with source/evidence and update programme status. If post-merge acceptance fails, reopen the issue and repair it.

If permissions, required review, approved hardware, credentials or another binding prerequisite is unavailable, preserve a reviewable draft PR and exact blocker. Never enroll credentials, change host privileges, fake physical acceptance or declare a merge that did not happen. A documented no-go completes a research issue only when its acceptance criteria explicitly allow it.

Canonical scope: [issues.json](https://github.com/techrote/runloc/blob/main/docs/programme/issues.json); repository mirror: [RUNLOC-012.md](https://github.com/techrote/runloc/blob/main/docs/programme/issues/RUNLOC-012.md).
