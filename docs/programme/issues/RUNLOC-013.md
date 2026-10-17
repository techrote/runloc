# RUNLOC-013 — Package the CLI and document a clean on-demand runner quickstart

Stage: **v0.1**. Planning status: **planned**. This issue is not implemented by publication of the programme.

## Dependencies and prerequisites

Depends on: [RUNLOC-010](https://github.com/techrote/runloc/issues/10), [RUNLOC-011](https://github.com/techrote/runloc/issues/11), [RUNLOC-012](https://github.com/techrote/runloc/issues/12)

None beyond accepted dependencies and ordinary local development tools.

Confirm dependency PRs are accepted on current main before coding. Follow-on issues do not block v0.1.

## Autonomous execution prompt

Implement **RUNLOC-013** end to end in `techrote/runloc`. Fetch current main; read this complete live issue and every comment, dependency result, overlapping PR and the linked instructions below. Use an isolated `runloc-013-short-name` branch. The owner authorizes the ordinary implementation, tests, PR and merge cycle under these contracts; routine confirmation is unnecessary. Do not start a later issue or deploy unrelated infrastructure.

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
- [docs/rag/10-RELEASE-OPERATIONS.md](https://github.com/techrote/runloc/blob/main/docs/rag/10-RELEASE-OPERATIONS.md)
- [docs/rag/03-IMAGES-STORAGE.md](https://github.com/techrote/runloc/blob/main/docs/rag/03-IMAGES-STORAGE.md)
- [docs/rag/06-DISPATCH-FALLBACK.md](https://github.com/techrote/runloc/blob/main/docs/rag/06-DISPATCH-FALLBACK.md)
- [docs/research/EZVM-FIELD-NOTES.md](https://github.com/techrote/runloc/blob/main/docs/research/EZVM-FIELD-NOTES.md)

## Scope to deliver

- Create source/wheel or equally small installable Python package, locked metadata, notices and supported-platform statement.
- Document clean setup/doctor/image/auth-preview/run/stats/disposal/recovery with reviewed workflow examples.
- Verify updates/rollback/retention/uninstall leave other projects and running immutable inputs untouched; provide precise space/download/capability estimates.

## Observable acceptance criteria

- A clean directory/user development environment reproduces the accepted shell-action runner using only documented steps and existing approved auth.
- Package contains own source/schemas/recipes/notices and no runtime disks, keys, seeded media, tokens, QEMU installer or guest archive.
- MIT scope and third-party source/distribution notices are accurate; no code copied from EzVM without explicit compatible terms.
- Examples target the real unique lease labels and approved candidate/definition inputs; installing/viewing docs never registers or dispatches.
- Update/rebuild of stale runner images and rollback preserve running leases and prior valid cache; uninstall is exact-scope and previewable.

## Required implementation/testing work

- Package file-content/metadata tests plus fresh venv smoke from built distribution rather than source import.
- Synthetic secret/binary exclusion, clean path with spaces, interrupted update and unrelated installation sentinel controls.
- Documented real one-job quickstart replay with receipt IDs and complete disposal, reusing unchanged qualified tree evidence only when identity is proved.

Also run `python scripts/check_repository.py` and `python -m unittest discover -s tests -p "test_*.py"`. From RUNLOC-001 onward run the consolidated `python scripts/check.py` and the issue's focused tests. All commands must target the intended checkout. Normal PR checks must require no VM/API credentials; separate physical/live acceptance is required only where specified and cannot be replaced by a mocked or all-skipped pass.

## Excluded scope

No bundled proprietary Windows image, global install/service, broad redistribution assumption or one-click claim hiding credentials/features.

## PR, automated checks and autonomous merge

Commit only clean intended source/tests/docs. Push a PR containing `Closes #<this issue number>`, a concise behavior summary, actual test/evidence links, limitations and RAG updates. Do not close this issue through a partial implementation. Inspect final diff and resolve material review findings. Wait for **all actual required automated checks on the exact PR head**, with about 120-second polling intervals. Fix relevant failures; do not disable checks or merge known-red work.

When dependencies and every acceptance clause are satisfied, required checks are green, review threads are resolved and no owner hold exists, squash-merge using the exact expected head. Do not use admin overrides or weaken branch protection. Verify the resulting main and post-merge checks, then add a factual completion comment with source/evidence and update programme status. If post-merge acceptance fails, reopen the issue and repair it.

If permissions, required review, approved hardware, credentials or another binding prerequisite is unavailable, preserve a reviewable draft PR and exact blocker. Never enroll credentials, change host privileges, fake physical acceptance or declare a merge that did not happen. A documented no-go completes a research issue only when its acceptance criteria explicitly allow it.

Canonical scope: [issues.json](https://github.com/techrote/runloc/blob/main/docs/programme/issues.json); repository mirror: [RUNLOC-013.md](https://github.com/techrote/runloc/blob/main/docs/programme/issues/RUNLOC-013.md).
