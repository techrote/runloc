# RUNLOC-010 — Dispatch independent hosted/private comparisons with offline fallback

Stage: **v0.1**. Planning status: **planned**. This issue is not implemented by publication of the programme.

## Dependencies and prerequisites

Depends on: [RUNLOC-007](https://github.com/techrote/runloc/issues/7), [RUNLOC-008](https://github.com/techrote/runloc/issues/8), [RUNLOC-009](https://github.com/techrote/runloc/issues/9)

Reviewed templates available on default branch, existing Actions write auth and explicit trusted qualification repository; unit tests never dispatch workflows.

Confirm dependency PRs are accepted on current main before coding. Follow-on issues do not block v0.1.

## Autonomous execution prompt

Implement **RUNLOC-010** end to end in `techrote/runloc`. Fetch current main; read this complete live issue and every comment, dependency result, overlapping PR and the linked instructions below. Use an isolated `runloc-010-short-name` branch. The owner authorizes the ordinary implementation, tests, PR and merge cycle under these contracts; routine confirmation is unnecessary. Do not start a later issue or deploy unrelated infrastructure.

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
- [docs/rag/06-DISPATCH-FALLBACK.md](https://github.com/techrote/runloc/blob/main/docs/rag/06-DISPATCH-FALLBACK.md)
- [docs/rag/05-GITHUB-RUNNERS.md](https://github.com/techrote/runloc/blob/main/docs/rag/05-GITHUB-RUNNERS.md)
- [docs/rag/09-METRICS-PERFORMANCE.md](https://github.com/techrote/runloc/blob/main/docs/rag/09-METRICS-PERFORMANCE.md)
- [docs/research/EZVM-FIELD-NOTES.md](https://github.com/techrote/runloc/blob/main/docs/research/EZVM-FIELD-NOTES.md)

## Scope to deliver

- Implement compare preview/dispatch and reviewed hosted/private workflow templates for identical Linux workloads.
- Dispatch hosted first, then optionally reserve/ready an owned VM and target its unique label; correlate both attempt/run identities.
- Implement finite private queue monitoring, exact-run cancellation and response-lost reconciliation while hosted remains independent.

## Observable acceptance criteria

- Offline/busy/disabled/unsupported/private boot/API failure cannot prevent or cancel accepted hosted execution.
- Both runs bind exact same candidate/input recipe/comparison ID and independently observed definition/profile/host identities.
- Workflow ref and candidate SHA are not confused; mutable-ref movement or mismatched assigned runner invalidates private evidence.
- Private disappearance after dispatch is bounded by controller queue TTL, not job timeout; controller-offline uncertainty is visible and reconciled on restart.
- Dispatch response loss cannot duplicate hosted/private runs; no automatic first-green cancellation or required-check policy change.

## Required implementation/testing work

- Stub call order/count tests and real adapters for documented successful dispatch response shapes, timeouts and run-ID reconciliation.
- Offline before/after readiness,429,permission failure,ref movement,wrong runner,duplicate intent and cancel-wrong-run negative controls.
- Live paired approved Linux workflow run with same candidate, result assertions and evidence; hosted continues after intentionally unavailable private lane.

Also run `python scripts/check_repository.py` and `python -m unittest discover -s tests -p "test_*.py"`. From RUNLOC-001 onward run the consolidated `python scripts/check.py` and the issue's focused tests. All commands must target the intended checkout. Normal PR checks must require no VM/API credentials; separate physical/live acceptance is required only where specified and cannot be replaced by a mocked or all-skipped pass.

## Excluded scope

No required matrix private leg, public PR auto-registration, production branch-rule edit or Windows/Linux equivalence claim.

## PR, automated checks and autonomous merge

Commit only clean intended source/tests/docs. Push a PR containing `Closes #<this issue number>`, a concise behavior summary, actual test/evidence links, limitations and RAG updates. Do not close this issue through a partial implementation. Inspect final diff and resolve material review findings. Wait for **all actual required automated checks on the exact PR head**, with about 120-second polling intervals. Fix relevant failures; do not disable checks or merge known-red work.

When dependencies and every acceptance clause are satisfied, required checks are green, review threads are resolved and no owner hold exists, squash-merge using the exact expected head. Do not use admin overrides or weaken branch protection. Verify the resulting main and post-merge checks, then add a factual completion comment with source/evidence and update programme status. If post-merge acceptance fails, reopen the issue and repair it.

If permissions, required review, approved hardware, credentials or another binding prerequisite is unavailable, preserve a reviewable draft PR and exact blocker. Never enroll credentials, change host privileges, fake physical acceptance or declare a merge that did not happen. A documented no-go completes a research issue only when its acceptance criteria explicitly allow it.

Canonical scope: [issues.json](https://github.com/techrote/runloc/blob/main/docs/programme/issues.json); repository mirror: [RUNLOC-010.md](https://github.com/techrote/runloc/blob/main/docs/programme/issues/RUNLOC-010.md).
