# RUNLOC-004 — Own QEMU launch, QMP and bounded Windows process lifetime

Stage: **v0.1**. Planning status: **planned**. This issue is not implemented by publication of the programme.

## Dependencies and prerequisites

Depends on: [RUNLOC-002](https://github.com/techrote/runloc/issues/2), [RUNLOC-003](https://github.com/techrote/runloc/issues/3)

Native Windows process tests can run hosted without QEMU; the separate boot smoke needs an approved WHPX host and accepted image.

Confirm dependency PRs are accepted on current main before coding. Follow-on issues do not block v0.1.

## Autonomous execution prompt

Implement **RUNLOC-004** end to end in `techrote/runloc`. Fetch current main; read this complete live issue and every comment, dependency result, overlapping PR and the linked instructions below. Use an isolated `runloc-004-short-name` branch. The owner authorizes the ordinary implementation, tests, PR and merge cycle under these contracts; routine confirmation is unnecessary. Do not start a later issue or deploy unrelated infrastructure.

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
- [docs/rag/02-HOST-QEMU.md](https://github.com/techrote/runloc/blob/main/docs/rag/02-HOST-QEMU.md)
- [docs/rag/07-SECURITY-RECOVERY.md](https://github.com/techrote/runloc/blob/main/docs/rag/07-SECURITY-RECOVERY.md)
- [docs/research/EZVM-FIELD-NOTES.md](https://github.com/techrote/runloc/blob/main/docs/research/EZVM-FIELD-NOTES.md)

## Scope to deliver

- Implement explicit WHPX argument arrays, controller-owned QMP stdio, independent serial capture and concurrent bounded stream drains.
- Contain QEMU before execution with a proved Windows ownership primitive; record executable/creation/root identity and durable lease association.
- Implement status/graceful stop/contained termination with deadlines and quarantine on ambiguity.

## Observable acceptance criteria

- Start returns on the intended readiness boundary without waiting for a long-lived child to close captured pipes.
- Supervisor death terminates its contained process tree; a reused PID or unrelated same-name process is never stopped.
- WHPX launch does not silently fall back; unsupported containment or requested accelerator fails closed before useful execution.
- No guest-reachable QMP TCP endpoint, host share or leaked process handle; stop confirms owned exit before releasing storage.

## Required implementation/testing work

- Native Windows lightweight process tests: captured start, descendant holding pipe, suspended containment, timeout, abrupt supervisor exit and handle lifetime.
- PID reuse/executable/root mismatch negative controls with unrelated process sentinel surviving.
- QMP protocol/error/EOF/output-flood tests and a bounded real disposable WHPX boot/stop smoke; mocked arguments are not physical execution proof.

Also run `python scripts/check_repository.py` and `python -m unittest discover -s tests -p "test_*.py"`. From RUNLOC-001 onward run the consolidated `python scripts/check.py` and the issue's focused tests. All commands must target the intended checkout. Normal PR checks must require no VM/API credentials; separate physical/live acceptance is required only where specified and cannot be replaced by a mocked or all-skipped pass.

## Excluded scope

No owner VM control, blanket process kill, host service, nested virtualization or Linux/KVM support.

## PR, automated checks and autonomous merge

Commit only clean intended source/tests/docs. Push a PR containing `Closes #<this issue number>`, a concise behavior summary, actual test/evidence links, limitations and RAG updates. Do not close this issue through a partial implementation. Inspect final diff and resolve material review findings. Wait for **all actual required automated checks on the exact PR head**, with about 120-second polling intervals. Fix relevant failures; do not disable checks or merge known-red work.

When dependencies and every acceptance clause are satisfied, required checks are green, review threads are resolved and no owner hold exists, squash-merge using the exact expected head. Do not use admin overrides or weaken branch protection. Verify the resulting main and post-merge checks, then add a factual completion comment with source/evidence and update programme status. If post-merge acceptance fails, reopen the issue and repair it.

If permissions, required review, approved hardware, credentials or another binding prerequisite is unavailable, preserve a reviewable draft PR and exact blocker. Never enroll credentials, change host privileges, fake physical acceptance or declare a merge that did not happen. A documented no-go completes a research issue only when its acceptance criteria explicitly allow it.

Canonical scope: [issues.json](https://github.com/techrote/runloc/blob/main/docs/programme/issues.json); repository mirror: [RUNLOC-004.md](https://github.com/techrote/runloc/blob/main/docs/programme/issues/RUNLOC-004.md).
