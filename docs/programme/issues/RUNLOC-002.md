# RUNLOC-002 — Implement fail-fast host doctor and verified local tool acquisition

Stage: **v0.1**. Planning status: **planned**. This issue is not implemented by publication of the programme.

## Dependencies and prerequisites

Depends on: [RUNLOC-001](https://github.com/techrote/runloc/issues/1)

None beyond accepted dependencies and ordinary local development tools.

Confirm dependency PRs are accepted on current main before coding. Follow-on issues do not block v0.1.

## Autonomous execution prompt

Implement **RUNLOC-002** end to end in `techrote/runloc`. Fetch current main; read this complete live issue and every comment, dependency result, overlapping PR and the linked instructions below. Use an isolated `runloc-002-short-name` branch. The owner authorizes the ordinary implementation, tests, PR and merge cycle under these contracts; routine confirmation is unnecessary. Do not start a later issue or deploy unrelated infrastructure.

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
- [docs/rag/03-IMAGES-STORAGE.md](https://github.com/techrote/runloc/blob/main/docs/rag/03-IMAGES-STORAGE.md)
- [docs/rag/07-SECURITY-RECOVERY.md](https://github.com/techrote/runloc/blob/main/docs/rag/07-SECURITY-RECOVERY.md)
- [docs/research/EZVM-FIELD-NOTES.md](https://github.com/techrote/runloc/blob/main/docs/research/EZVM-FIELD-NOTES.md)

## Scope to deliver

- Implement doctor with explicit observed host capabilities, headroom, owned paths and exact synthetic key/control-file ACL probes.
- Introduce reviewed input locks and local artifact download/extraction/cache adapters for the QEMU toolchain; record provenance and notices.
- Handle offline cache, deadlines, archive/path bounds, partial downloads and atomic verified promotion without running a global installer.

## Observable acceptance criteria

- Unsupported/disabled WHPX is unavailable, not a runtime PASS or implicit TCG selection.
- The actual private-file protection sequence works as a standard user on supported Windows; broad explicit ACL fixtures are removed and no SeSecurityPrivilege/elevation is required.
- Digest mismatch, malformed/oversized archive, traversal entry and interrupted promotion cannot replace a valid cache.
- Doctor is read-only outside synthetic owned fixtures and prints finite resource/download requirements before mutation.

## Required implementation/testing work

- Windows native ACL positive/negative controls, exact failing-path regression inspired by the EzVM pilot and source import checks.
- Injected downloader/hash/extractor tests for mismatch, redirect policy, ENOSPC, locked destination, offline valid/invalid cache and interrupted writes.
- Construct no real guest in PR CI; opt-in acquisition proof records actual tool identities, exit and hashes.

Also run `python scripts/check_repository.py` and `python -m unittest discover -s tests -p "test_*.py"`. From RUNLOC-001 onward run the consolidated `python scripts/check.py` and the issue's focused tests. All commands must target the intended checkout. Normal PR checks must require no VM/API credentials; separate physical/live acceptance is required only where specified and cannot be replaced by a mocked or all-skipped pass.

## Excluded scope

No enabling host features, privilege grants, owner-patch import, image build, runner auth or physical WHPX qualification.

## PR, automated checks and autonomous merge

Commit only clean intended source/tests/docs. Push a PR containing `Closes #<this issue number>`, a concise behavior summary, actual test/evidence links, limitations and RAG updates. Do not close this issue through a partial implementation. Inspect final diff and resolve material review findings. Wait for **all actual required automated checks on the exact PR head**, with about 120-second polling intervals. Fix relevant failures; do not disable checks or merge known-red work.

When dependencies and every acceptance clause are satisfied, required checks are green, review threads are resolved and no owner hold exists, squash-merge using the exact expected head. Do not use admin overrides or weaken branch protection. Verify the resulting main and post-merge checks, then add a factual completion comment with source/evidence and update programme status. If post-merge acceptance fails, reopen the issue and repair it.

If permissions, required review, approved hardware, credentials or another binding prerequisite is unavailable, preserve a reviewable draft PR and exact blocker. Never enroll credentials, change host privileges, fake physical acceptance or declare a merge that did not happen. A documented no-go completes a research issue only when its acceptance criteria explicitly allow it.

Canonical scope: [issues.json](https://github.com/techrote/runloc/blob/main/docs/programme/issues.json); repository mirror: [RUNLOC-002.md](https://github.com/techrote/runloc/blob/main/docs/programme/issues/RUNLOC-002.md).
