# RUNLOC-007 — Implement host-only GitHub auth and repository-scoped JIT runners

Stage: **v0.1**. Planning status: **planned**. This issue is not implemented by publication of the programme.

## Dependencies and prerequisites

Depends on: [RUNLOC-001](https://github.com/techrote/runloc/issues/1), [RUNLOC-006](https://github.com/techrote/runloc/issues/6)

Existing host auth/App with repository administration capability and an approved qualification repository (techrote/runloc is the intended test repository); no production secrets.

Confirm dependency PRs are accepted on current main before coding. Follow-on issues do not block v0.1.

## Autonomous execution prompt

Implement **RUNLOC-007** end to end in `techrote/runloc`. Fetch current main; read this complete live issue and every comment, dependency result, overlapping PR and the linked instructions below. Use an isolated `runloc-007-short-name` branch. The owner authorizes the ordinary implementation, tests, PR and merge cycle under these contracts; routine confirmation is unnecessary. Do not start a later issue or deploy unrelated infrastructure.

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
- [docs/rag/05-GITHUB-RUNNERS.md](https://github.com/techrote/runloc/blob/main/docs/rag/05-GITHUB-RUNNERS.md)
- [docs/rag/06-DISPATCH-FALLBACK.md](https://github.com/techrote/runloc/blob/main/docs/rag/06-DISPATCH-FALLBACK.md)
- [docs/rag/07-SECURITY-RECOVERY.md](https://github.com/techrote/runloc/blob/main/docs/rag/07-SECURITY-RECOVERY.md)
- [docs/research/EZVM-FIELD-NOTES.md](https://github.com/techrote/runloc/blob/main/docs/research/EZVM-FIELD-NOTES.md)

## Scope to deliver

- Implement credential-provider and documented GitHub REST boundaries with pinned API semantics, finite requests and injected fixtures.
- Acquire repository-scoped JIT configuration only for a ready owned guest and register a unique Linux/X64/profile/lease identity.
- Observe runner readiness and exact-ID removal; keep remote cleanup uncertainty and sensitive payloads out of durable/public state.

## Observable acceptance criteria

- Host authorization never enters guest/base/logs; guest receives only its single-use capability via the accepted006 channel.
- Unique runner ID/name/label/repository association is verified; generic self-hosted routing is insufficient.
- Accepted-but-response-lost registration is reconciled before retry, preventing duplicate runners; permissions and rate limits fail clearly.
- Observed one-job registration and deregistration are distinct from VM disposal; network errors never prove absence or success.

## Required implementation/testing work

- Recorded synthetic fixtures for success, timeout-after-accept,429/Retry-After,401/403/404/409/5xx, pagination and stale/incorrect identity.
- Secret redaction and no-credential-call unit CI; exact-ID deletion cannot remove another runner sentinel.
- Explicitly approved live test-repository registration/online/removal proof with API IDs and guest-channel evidence; no real job required yet.

Also run `python scripts/check_repository.py` and `python -m unittest discover -s tests -p "test_*.py"`. From RUNLOC-001 onward run the consolidated `python scripts/check.py` and the issue's focused tests. All commands must target the intended checkout. Normal PR checks must require no VM/API credentials; separate physical/live acceptance is required only where specified and cannot be replaced by a mocked or all-skipped pass.

## Excluded scope

No PAT enrollment, org-wide fleet, runner service on host, public-fork trigger or runner-protocol implementation.

## PR, automated checks and autonomous merge

Commit only clean intended source/tests/docs. Push a PR containing `Closes #<this issue number>`, a concise behavior summary, actual test/evidence links, limitations and RAG updates. Do not close this issue through a partial implementation. Inspect final diff and resolve material review findings. Wait for **all actual required automated checks on the exact PR head**, with about 120-second polling intervals. Fix relevant failures; do not disable checks or merge known-red work.

When dependencies and every acceptance clause are satisfied, required checks are green, review threads are resolved and no owner hold exists, squash-merge using the exact expected head. Do not use admin overrides or weaken branch protection. Verify the resulting main and post-merge checks, then add a factual completion comment with source/evidence and update programme status. If post-merge acceptance fails, reopen the issue and repair it.

If permissions, required review, approved hardware, credentials or another binding prerequisite is unavailable, preserve a reviewable draft PR and exact blocker. Never enroll credentials, change host privileges, fake physical acceptance or declare a merge that did not happen. A documented no-go completes a research issue only when its acceptance criteria explicitly allow it.

Canonical scope: [issues.json](https://github.com/techrote/runloc/blob/main/docs/programme/issues.json); repository mirror: [RUNLOC-007.md](https://github.com/techrote/runloc/blob/main/docs/programme/issues/RUNLOC-007.md).
