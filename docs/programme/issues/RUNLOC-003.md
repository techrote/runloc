# RUNLOC-003 — Implement lease reservations and one-level disposable QCOW2 storage

Stage: **v0.1**. Planning status: **planned**. This issue is not implemented by publication of the programme.

## Dependencies and prerequisites

Depends on: [RUNLOC-002](https://github.com/techrote/runloc/issues/2)

None beyond accepted dependencies and ordinary local development tools.

Confirm dependency PRs are accepted on current main before coding. Follow-on issues do not block v0.1.

## Autonomous execution prompt

Implement **RUNLOC-003** end to end in `techrote/runloc`. Fetch current main; read this complete live issue and every comment, dependency result, overlapping PR and the linked instructions below. Use an isolated `runloc-003-short-name` branch. The owner authorizes the ordinary implementation, tests, PR and merge cycle under these contracts; routine confirmation is unnecessary. Do not start a later issue or deploy unrelated infrastructure.

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
- [docs/rag/03-IMAGES-STORAGE.md](https://github.com/techrote/runloc/blob/main/docs/rag/03-IMAGES-STORAGE.md)
- [docs/rag/07-SECURITY-RECOVERY.md](https://github.com/techrote/runloc/blob/main/docs/rag/07-SECURITY-RECOVERY.md)
- [docs/research/EZVM-FIELD-NOTES.md](https://github.com/techrote/runloc/blob/main/docs/research/EZVM-FIELD-NOTES.md)

## Scope to deliver

- Create durable UUID leases, atomic journals/locks and single-guest resource admission using actual CPU/RAM/disk headroom.
- Create fresh one-level QCOW2 overlays and seed/control directories from explicit verified base descriptors; use synthetic tiny bases before the later prepared-image issue and validate actual backing metadata.
- Implement previewable scoped storage cleanup, sensitive-state marking, reservations and finite retention without deleting live references.

## Observable acceptance criteria

- Simultaneous controllers cannot reserve the same capacity, port or lease; a rejected reservation makes no partial guest.
- Changed/missing/external base, second-level chain, malformed metadata and path escape refuse boot preparation.
- Used/job-injected overlays cannot become clean bases or return to a pool; cleanup preserves referenced immutable inputs.
- ENOSPC, journal failure, moved cold root and stale lock recovery retain truth and previous valid state; unresolved ownership holds capacity visibly.

## Required implementation/testing work

- Real file-lock/process race tests and fake-clock/resource tests for oversubscription and lease reuse refusal.
- Synthetic qemu-img fixtures for backing/format/relocation plus bounded real tiny-image checks with verified tools.
- Traversal/junction/hardlink, live base reference, failed atomic replace and disk-full negative controls; assert unrelated sentinel files survive.

Also run `python scripts/check_repository.py` and `python -m unittest discover -s tests -p "test_*.py"`. From RUNLOC-001 onward run the consolidated `python scripts/check.py` and the issue's focused tests. All commands must target the intended checkout. Normal PR checks must require no VM/API credentials; separate physical/live acceptance is required only where specified and cannot be replaced by a mocked or all-skipped pass.

## Excluded scope

No guest execution, registered-runner pool, external API calls or general image portability product.

## PR, automated checks and autonomous merge

Commit only clean intended source/tests/docs. Push a PR containing `Closes #<this issue number>`, a concise behavior summary, actual test/evidence links, limitations and RAG updates. Do not close this issue through a partial implementation. Inspect final diff and resolve material review findings. Wait for **all actual required automated checks on the exact PR head**, with about 120-second polling intervals. Fix relevant failures; do not disable checks or merge known-red work.

When dependencies and every acceptance clause are satisfied, required checks are green, review threads are resolved and no owner hold exists, squash-merge using the exact expected head. Do not use admin overrides or weaken branch protection. Verify the resulting main and post-merge checks, then add a factual completion comment with source/evidence and update programme status. If post-merge acceptance fails, reopen the issue and repair it.

If permissions, required review, approved hardware, credentials or another binding prerequisite is unavailable, preserve a reviewable draft PR and exact blocker. Never enroll credentials, change host privileges, fake physical acceptance or declare a merge that did not happen. A documented no-go completes a research issue only when its acceptance criteria explicitly allow it.

Canonical scope: [issues.json](https://github.com/techrote/runloc/blob/main/docs/programme/issues.json); repository mirror: [RUNLOC-003.md](https://github.com/techrote/runloc/blob/main/docs/programme/issues/RUNLOC-003.md).
