# RUNLOC-008 — Orchestrate one real job through collection and complete disposal

Stage: **v0.1**. Planning status: **planned**. This issue is not implemented by publication of the programme.

## Dependencies and prerequisites

Depends on: [RUNLOC-003](https://github.com/techrote/runloc/issues/3), [RUNLOC-004](https://github.com/techrote/runloc/issues/4), [RUNLOC-006](https://github.com/techrote/runloc/issues/6), [RUNLOC-007](https://github.com/techrote/runloc/issues/7)

Accepted physical adapters and explicit host authorization for the trusted qualification workflow; ordinary PR tests remain fully offline.

Confirm dependency PRs are accepted on current main before coding. Follow-on issues do not block v0.1.

## Autonomous execution prompt

Implement **RUNLOC-008** end to end in `techrote/runloc`. Fetch current main; read this complete live issue and every comment, dependency result, overlapping PR and the linked instructions below. Use an isolated `runloc-008-short-name` branch. The owner authorizes the ordinary implementation, tests, PR and merge cycle under these contracts; routine confirmation is unnecessary. Do not start a later issue or deploy unrelated infrastructure.

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
- [docs/rag/01-ARCHITECTURE-STATE.md](https://github.com/techrote/runloc/blob/main/docs/rag/01-ARCHITECTURE-STATE.md)
- [docs/rag/05-GITHUB-RUNNERS.md](https://github.com/techrote/runloc/blob/main/docs/rag/05-GITHUB-RUNNERS.md)
- [docs/rag/07-SECURITY-RECOVERY.md](https://github.com/techrote/runloc/blob/main/docs/rag/07-SECURITY-RECOVERY.md)
- [docs/research/EZVM-FIELD-NOTES.md](https://github.com/techrote/runloc/blob/main/docs/research/EZVM-FIELD-NOTES.md)

## Scope to deliver

- Implement foreground plan/run/status/stop/reconcile single-lease supervisor and phase deadlines, using accepted adapters.
- Bind an approved workflow definition/candidate/job to the unique ready runner; persist external write intent and observed IDs.
- Collect bounded redacted diagnostics, cancel only owned work when needed, terminate VM and remove local sensitive state with explicit remote cleanup obligations.

## Observable acceptance criteria

- An actual approved Linux job completes on its assigned unique runner and is associated with exact candidate, workflow/run/job/attempt and lease.
- A deliberately failing job remains a failed outcome even when cleanup succeeds; runner-online/guest PASS/exit without API conclusion cannot substitute.
- One used VM never accepts a second job; overlay/seed/control keys disappear after confirmed QEMU exit and registration disposition is known.
- Controller restart, cancellation, collection failure and cleanup API outage reconcile without re-executing a job or losing the original cause; unresolved state is quarantined.

## Required implementation/testing work

- State-machine/fake-clock tests at every transition and exact phase timeout; failed-job and queue expiry controls.
- Real one-job success plus failed job with QEMU exit, disk/seed/key removal, API conclusion and exact runner disposition evidence.
- Two successive fresh leases prove distinct identity and no sentinel carry-over; second-job scheduling cannot use the first runner.

Also run `python scripts/check_repository.py` and `python -m unittest discover -s tests -p "test_*.py"`. From RUNLOC-001 onward run the consolidated `python scripts/check.py` and the issue's focused tests. All commands must target the intended checkout. Normal PR checks must require no VM/API credentials; separate physical/live acceptance is required only where specified and cannot be replaced by a mocked or all-skipped pass.

## Excluded scope

No multi-guest pool, autoscaling, gate promotion, broad workflow trust or success based only on logs.

## PR, automated checks and autonomous merge

Commit only clean intended source/tests/docs. Push a PR containing `Closes #<this issue number>`, a concise behavior summary, actual test/evidence links, limitations and RAG updates. Do not close this issue through a partial implementation. Inspect final diff and resolve material review findings. Wait for **all actual required automated checks on the exact PR head**, with about 120-second polling intervals. Fix relevant failures; do not disable checks or merge known-red work.

When dependencies and every acceptance clause are satisfied, required checks are green, review threads are resolved and no owner hold exists, squash-merge using the exact expected head. Do not use admin overrides or weaken branch protection. Verify the resulting main and post-merge checks, then add a factual completion comment with source/evidence and update programme status. If post-merge acceptance fails, reopen the issue and repair it.

If permissions, required review, approved hardware, credentials or another binding prerequisite is unavailable, preserve a reviewable draft PR and exact blocker. Never enroll credentials, change host privileges, fake physical acceptance or declare a merge that did not happen. A documented no-go completes a research issue only when its acceptance criteria explicitly allow it.

Canonical scope: [issues.json](https://github.com/techrote/runloc/blob/main/docs/programme/issues.json); repository mirror: [RUNLOC-008.md](https://github.com/techrote/runloc/blob/main/docs/programme/issues/RUNLOC-008.md).
