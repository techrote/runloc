# RUNLOC-011 — Qualify crash recovery, cancellation and failure cleanup

Stage: **v0.1**. Planning status: **planned**. This issue is not implemented by publication of the programme.

## Dependencies and prerequisites

Depends on: [RUNLOC-008](https://github.com/techrote/runloc/issues/8), [RUNLOC-009](https://github.com/techrote/runloc/issues/9), [RUNLOC-010](https://github.com/techrote/runloc/issues/10)

None beyond accepted dependencies and ordinary local development tools.

Confirm dependency PRs are accepted on current main before coding. Follow-on issues do not block v0.1.

## Autonomous execution prompt

Implement **RUNLOC-011** end to end in `techrote/runloc`. Fetch current main; read this complete live issue and every comment, dependency result, overlapping PR and the linked instructions below. Use an isolated `runloc-011-short-name` branch. The owner authorizes the ordinary implementation, tests, PR and merge cycle under these contracts; routine confirmation is unnecessary. Do not start a later issue or deploy unrelated infrastructure.

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
- [docs/rag/07-SECURITY-RECOVERY.md](https://github.com/techrote/runloc/blob/main/docs/rag/07-SECURITY-RECOVERY.md)
- [docs/rag/02-HOST-QEMU.md](https://github.com/techrote/runloc/blob/main/docs/rag/02-HOST-QEMU.md)
- [docs/research/EZVM-FIELD-NOTES.md](https://github.com/techrote/runloc/blob/main/docs/research/EZVM-FIELD-NOTES.md)

## Scope to deliver

- Add a bounded fault-injection qualification runner and recovery matrix covering each durable transition/ambiguous external-write window.
- Exercise native containment, storage/credential/API obligations, queue disappearance, log flood and resource errors.
- Repair narrowly evidenced integration defects, retaining original failure records and explicit cleanup/quarantine outcomes.

## Observable acceptance criteria

- Controller death before/after registration/dispatch and during running/collection leaves no unowned active VM or reused used lease.
- Restart does not repeat completed/unknown external actions blindly; remote uncertainty and capacity obligations remain visible.
- Job failure/cancellation/timeout and disk/log/transport failures never become success from cleanup or a skipped check.
- Unrelated QEMU/process/file/runner sentinels survive all recovery operations, including PID reuse and path reparse cases.
- The report distinguishes deterministic unit faults, native process proofs and real VM/API scenarios; physical gates remain open if missing.

## Required implementation/testing work

- Native Windows controller/child-pipe kill, reused PID, containment failure and owned scope tests.
- ENOSPC at download/journal/collection/promotion, wrong identity, log flood, API outage/removal failure and host-restart reconciliation simulations.
- At least real controller-death during one guest lease, failed-job disposal and offline-after-private-dispatch proof using approved test assets.

Also run `python scripts/check_repository.py` and `python -m unittest discover -s tests -p "test_*.py"`. From RUNLOC-001 onward run the consolidated `python scripts/check.py` and the issue's focused tests. All commands must target the intended checkout. Normal PR checks must require no VM/API credentials; separate physical/live acceptance is required only where specified and cannot be replaced by a mocked or all-skipped pass.

## Excluded scope

No escape testing, owner infrastructure disruption, wildcard cleanup, hypervisor tuning or broad rewrite unrelated to observed defects.

## PR, automated checks and autonomous merge

Commit only clean intended source/tests/docs. Push a PR containing `Closes #<this issue number>`, a concise behavior summary, actual test/evidence links, limitations and RAG updates. Do not close this issue through a partial implementation. Inspect final diff and resolve material review findings. Wait for **all actual required automated checks on the exact PR head**, with about 120-second polling intervals. Fix relevant failures; do not disable checks or merge known-red work.

When dependencies and every acceptance clause are satisfied, required checks are green, review threads are resolved and no owner hold exists, squash-merge using the exact expected head. Do not use admin overrides or weaken branch protection. Verify the resulting main and post-merge checks, then add a factual completion comment with source/evidence and update programme status. If post-merge acceptance fails, reopen the issue and repair it.

If permissions, required review, approved hardware, credentials or another binding prerequisite is unavailable, preserve a reviewable draft PR and exact blocker. Never enroll credentials, change host privileges, fake physical acceptance or declare a merge that did not happen. A documented no-go completes a research issue only when its acceptance criteria explicitly allow it.

Canonical scope: [issues.json](https://github.com/techrote/runloc/blob/main/docs/programme/issues.json); repository mirror: [RUNLOC-011.md](https://github.com/techrote/runloc/blob/main/docs/programme/issues/RUNLOC-011.md).
