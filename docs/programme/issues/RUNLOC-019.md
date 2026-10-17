# RUNLOC-019 — Design and qualify private-result promotion with hosted fallback

Stage: **follow-on**. Planning status: **planned**. This issue is not implemented by publication of the programme.

## Dependencies and prerequisites

Depends on: [RUNLOC-010](https://github.com/techrote/runloc/issues/10), [RUNLOC-012](https://github.com/techrote/runloc/issues/12), [RUNLOC-014](https://github.com/techrote/runloc/issues/14)

The owner must authorize the concrete required-check policy for the target repository; until then complete a reviewable staging design/PR without changing production requirements.

Confirm dependency PRs are accepted on current main before coding. Follow-on issues do not block v0.1.

## Autonomous execution prompt

Implement **RUNLOC-019** end to end in `techrote/runloc`. Fetch current main; read this complete live issue and every comment, dependency result, overlapping PR and the linked instructions below. Use an isolated `runloc-019-short-name` branch. The owner authorizes the ordinary implementation, tests, PR and merge cycle under these contracts; routine confirmation is unnecessary. Do not start a later issue or deploy unrelated infrastructure.

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
- [docs/rag/09-METRICS-PERFORMANCE.md](https://github.com/techrote/runloc/blob/main/docs/rag/09-METRICS-PERFORMANCE.md)
- [docs/research/EZVM-FIELD-NOTES.md](https://github.com/techrote/runloc/blob/main/docs/research/EZVM-FIELD-NOTES.md)

## Scope to deliver

- Specify one stable required acceptance check which may use qualified equivalent private results while hosted continues/falls back.
- Bind trusted controller evidence to exact candidate, workflow definition, recipe/profile and actual private job/disposal; define finite decision and failure semantics.
- Implement only after explicit repository policy authorization and demonstrated equivalent results/performance; migrate requirements transparently with rollback.

## Observable acceptance criteria

- An offline/failed/unqualified private attempt cannot strand the required gate or suppress meaningful hosted failure.
- Forged guest PASS, wrong candidate, reused receipt, different platform/tool profile or stale workflow definition cannot satisfy the gate.
- Host/controller outage and delayed/duplicate results have deterministic timeout/fallback behavior; a fast missing/failed assertion is never accepted.
- Branch-rule/check-policy changes are previewed, reviewed and explicitly authorized, not an installation side effect.
- Real equivalent-workload tests show shorter accepted completion where justified, while known failing cases remain failures; comparison-only mode remains available.

## Required implementation/testing work

- Truth-table/state tests for both lanes success/failure/cancel/timeout/offline/race, mismatched source/recipe and spoofed/replayed evidence.
- Staging repository end-to-end gate checks with exact statuses/permissions and rollback; ordinary PR CI cannot access admin credentials.
- Publish measured merge-wait comparison, parity evidence and failure cases before enabling production policy.

Also run `python scripts/check_repository.py` and `python -m unittest discover -s tests -p "test_*.py"`. From RUNLOC-001 onward run the consolidated `python scripts/check.py` and the issue's focused tests. All commands must target the intended checkout. Normal PR checks must require no VM/API credentials; separate physical/live acceptance is required only where specified and cannot be replaced by a mocked or all-skipped pass.

## Excluded scope

No first-green-wins shortcut, silent branch-protection bypass, generic all-checks assertion or Windows/Linux result substitution.

## PR, automated checks and autonomous merge

Commit only clean intended source/tests/docs. Push a PR containing `Closes #<this issue number>`, a concise behavior summary, actual test/evidence links, limitations and RAG updates. Do not close this issue through a partial implementation. Inspect final diff and resolve material review findings. Wait for **all actual required automated checks on the exact PR head**, with about 120-second polling intervals. Fix relevant failures; do not disable checks or merge known-red work.

When dependencies and every acceptance clause are satisfied, required checks are green, review threads are resolved and no owner hold exists, squash-merge using the exact expected head. Do not use admin overrides or weaken branch protection. Verify the resulting main and post-merge checks, then add a factual completion comment with source/evidence and update programme status. If post-merge acceptance fails, reopen the issue and repair it.

If permissions, required review, approved hardware, credentials or another binding prerequisite is unavailable, preserve a reviewable draft PR and exact blocker. Never enroll credentials, change host privileges, fake physical acceptance or declare a merge that did not happen. A documented no-go completes a research issue only when its acceptance criteria explicitly allow it.

Canonical scope: [issues.json](https://github.com/techrote/runloc/blob/main/docs/programme/issues.json); repository mirror: [RUNLOC-019.md](https://github.com/techrote/runloc/blob/main/docs/programme/issues/RUNLOC-019.md).
