# RUNLOC-016 — Evaluate Windows guest runners and nested-virtualization limits

Stage: **follow-on**. Planning status: **planned**. This issue is not implemented by publication of the programme.

## Dependencies and prerequisites

Depends on: [RUNLOC-014](https://github.com/techrote/runloc/issues/14)

None beyond accepted dependencies and ordinary local development tools.

Confirm dependency PRs are accepted on current main before coding. Follow-on issues do not block v0.1.

## Autonomous execution prompt

Implement **RUNLOC-016** end to end in `techrote/runloc`. Fetch current main; read this complete live issue and every comment, dependency result, overlapping PR and the linked instructions below. Use an isolated `runloc-016-short-name` branch. The owner authorizes the ordinary implementation, tests, PR and merge cycle under these contracts; routine confirmation is unnecessary. Do not start a later issue or deploy unrelated infrastructure.

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
- [docs/rag/10-RELEASE-OPERATIONS.md](https://github.com/techrote/runloc/blob/main/docs/rag/10-RELEASE-OPERATIONS.md)
- [docs/research/EZVM-FIELD-NOTES.md](https://github.com/techrote/runloc/blob/main/docs/research/EZVM-FIELD-NOTES.md)

## Scope to deliver

- Produce a bounded feasibility study for Windows GitHub runner guests, supported/licensed media and unattended unique disposable image recipe.
- Separate ordinary Windows jobs from Windows jobs that themselves require WHPX/nested virtualization; evaluate actual platform constraints.
- Define a follow-up implementation plan or evidenced no-go, with measured costs and no unsupported support labels.

## Observable acceptance criteria

- Report explicitly separates host OS, guest OS, job platform, acceleration and any nested requirements.
- Media acquisition/distribution/licensing prerequisites are documented; no unauthorized proprietary image redistribution or silent host change.
- If an approved image is available, a bounded disposable ordinary Windows job has actual evidence; nested WHPX is separately tested or explicitly unsupported.
- If prerequisites or nested support are absent, a reviewed no-go/blocked feasibility outcome can close this research issue without claiming product support.
- Any proposed implementation is new bounded issues with tests, not an unreviewed extension enabled during the spike.

## Required implementation/testing work

- Decision matrix and evidence validation reject Linux-as-Windows or capability-detection-as-execution claims.
- Optional real licensed Windows image/job experiment has explicit source/profile/cleanup receipts and finite bounds.
- Document reproducible negative evidence and exact follow-up gates for any unsupported case.

Also run `python scripts/check_repository.py` and `python -m unittest discover -s tests -p "test_*.py"`. From RUNLOC-001 onward run the consolidated `python scripts/check.py` and the issue's focused tests. All commands must target the intended checkout. Normal PR checks must require no VM/API credentials; separate physical/live acceptance is required only where specified and cannot be replaced by a mocked or all-skipped pass.

## Excluded scope

No assumption that the original EzVM Windows qualification now works inside a Linux or Windows guest; no production feature promise.

## PR, automated checks and autonomous merge

Commit only clean intended source/tests/docs. Push a PR containing `Closes #<this issue number>`, a concise behavior summary, actual test/evidence links, limitations and RAG updates. Do not close this issue through a partial implementation. Inspect final diff and resolve material review findings. Wait for **all actual required automated checks on the exact PR head**, with about 120-second polling intervals. Fix relevant failures; do not disable checks or merge known-red work.

When dependencies and every acceptance clause are satisfied, required checks are green, review threads are resolved and no owner hold exists, squash-merge using the exact expected head. Do not use admin overrides or weaken branch protection. Verify the resulting main and post-merge checks, then add a factual completion comment with source/evidence and update programme status. If post-merge acceptance fails, reopen the issue and repair it.

If permissions, required review, approved hardware, credentials or another binding prerequisite is unavailable, preserve a reviewable draft PR and exact blocker. Never enroll credentials, change host privileges, fake physical acceptance or declare a merge that did not happen. A documented no-go completes a research issue only when its acceptance criteria explicitly allow it.

Canonical scope: [issues.json](https://github.com/techrote/runloc/blob/main/docs/programme/issues.json); repository mirror: [RUNLOC-016.md](https://github.com/techrote/runloc/blob/main/docs/programme/issues/RUNLOC-016.md).
