# RUNLOC-018 — Evaluate official scale-set integration and future CI-provider adapters

Stage: **follow-on**. Planning status: **planned**. This issue is not implemented by publication of the programme.

## Dependencies and prerequisites

Depends on: [RUNLOC-014](https://github.com/techrote/runloc/issues/14), [RUNLOC-015](https://github.com/techrote/runloc/issues/15)

None beyond accepted dependencies and ordinary local development tools.

Confirm dependency PRs are accepted on current main before coding. Follow-on issues do not block v0.1.

## Autonomous execution prompt

Implement **RUNLOC-018** end to end in `techrote/runloc`. Fetch current main; read this complete live issue and every comment, dependency result, overlapping PR and the linked instructions below. Use an isolated `runloc-018-short-name` branch. The owner authorizes the ordinary implementation, tests, PR and merge cycle under these contracts; routine confirmation is unnecessary. Do not start a later issue or deploy unrelated infrastructure.

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

- Evaluate the official GitHub scale-set client/ARC fit before extending manual dispatch to autoscaling.
- Document the minimal runner-provider interface and an optional signed-event/polling design that preserves local admission and cleanup.
- Deliver a small isolated feasibility prototype or explicit no-go plus scoped implementation issues; keep deployed v0.1 behavior unchanged.

## Observable acceptance criteria

- Compare supported official approaches, permissions, operational footprint and queue semantics using current primary references.
- No custom undocumented runner protocol, Kubernetes requirement or public inbound listener is introduced as a default.
- Duplicate/out-of-order events, lost acknowledgements, offline host and unavailable capacity have concrete decision/test contracts.
- Other CI-provider exploration does not weaken GitHub job/credential/source association or claim an implemented provider.
- A reviewed evidence-backed go/no-go completes the research issue; production autoscaling requires separate implementation acceptance.

## Required implementation/testing work

- Synthetic signed-event/replay/order/expiry/admission fixtures and permission-failure tests in an isolated prototype.
- Provider-contract comparison verifies at-most-one execution, evidence identity and teardown obligations.
- Record actual prototype limitations and bounded follow-up tasks; no live production registration.

Also run `python scripts/check_repository.py` and `python -m unittest discover -s tests -p "test_*.py"`. From RUNLOC-001 onward run the consolidated `python scripts/check.py` and the issue's focused tests. All commands must target the intended checkout. Normal PR checks must require no VM/API credentials; separate physical/live acceptance is required only where specified and cannot be replaced by a mocked or all-skipped pass.

## Excluded scope

No unattended webhook deployment, auto-enrollment of admin credentials, multi-host fleet or promise that a spike is a production feature.

## PR, automated checks and autonomous merge

Commit only clean intended source/tests/docs. Push a PR containing `Closes #<this issue number>`, a concise behavior summary, actual test/evidence links, limitations and RAG updates. Do not close this issue through a partial implementation. Inspect final diff and resolve material review findings. Wait for **all actual required automated checks on the exact PR head**, with about 120-second polling intervals. Fix relevant failures; do not disable checks or merge known-red work.

When dependencies and every acceptance clause are satisfied, required checks are green, review threads are resolved and no owner hold exists, squash-merge using the exact expected head. Do not use admin overrides or weaken branch protection. Verify the resulting main and post-merge checks, then add a factual completion comment with source/evidence and update programme status. If post-merge acceptance fails, reopen the issue and repair it.

If permissions, required review, approved hardware, credentials or another binding prerequisite is unavailable, preserve a reviewable draft PR and exact blocker. Never enroll credentials, change host privileges, fake physical acceptance or declare a merge that did not happen. A documented no-go completes a research issue only when its acceptance criteria explicitly allow it.

Canonical scope: [issues.json](https://github.com/techrote/runloc/blob/main/docs/programme/issues.json); repository mirror: [RUNLOC-018.md](https://github.com/techrote/runloc/blob/main/docs/programme/issues/RUNLOC-018.md).
