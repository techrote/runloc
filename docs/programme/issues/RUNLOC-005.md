# RUNLOC-005 — Build and qualify a credential-free Linux runner image recipe

Stage: **v0.1**. Planning status: **planned**. This issue is not implemented by publication of the programme.

## Dependencies and prerequisites

Depends on: [RUNLOC-002](https://github.com/techrote/runloc/issues/2), [RUNLOC-004](https://github.com/techrote/runloc/issues/4)

Supported Windows/WHPX host and explicitly selected download sources; if unavailable keep physical image acceptance open, not mocked green.

Confirm dependency PRs are accepted on current main before coding. Follow-on issues do not block v0.1.

## Autonomous execution prompt

Implement **RUNLOC-005** end to end in `techrote/runloc`. Fetch current main; read this complete live issue and every comment, dependency result, overlapping PR and the linked instructions below. Use an isolated `runloc-005-short-name` branch. The owner authorizes the ordinary implementation, tests, PR and merge cycle under these contracts; routine confirmation is unnecessary. Do not start a later issue or deploy unrelated infrastructure.

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
- [docs/rag/03-IMAGES-STORAGE.md](https://github.com/techrote/runloc/blob/main/docs/rag/03-IMAGES-STORAGE.md)
- [docs/rag/04-GUEST-CONTRACT.md](https://github.com/techrote/runloc/blob/main/docs/rag/04-GUEST-CONTRACT.md)
- [docs/rag/10-RELEASE-OPERATIONS.md](https://github.com/techrote/runloc/blob/main/docs/rag/10-RELEASE-OPERATIONS.md)
- [docs/research/EZVM-FIELD-NOTES.md](https://github.com/techrote/runloc/blob/main/docs/research/EZVM-FIELD-NOTES.md)

## Scope to deliver

- Implement image build/inspect with pinned Ubuntu 24.04 x64 input, explicit guest packages and official runner dependencies/archive.
- Build in an owned bounded VM, sanitize identity and credentials, cleanly stop, validate and atomically publish base+manifest.
- Record exact inputs, recipe, resulting digest, runner-version freshness and supported shell-action tool profile; add notices and rebuild procedure.

## Observable acceptance criteria

- A verified reusable base has no registration, JIT configuration, repository worktree, private keys, job state or reused lease machine identity.
- Failed or interrupted build cannot overwrite the previous valid base or publish a partially prepared image.
- Actual guest inspection demonstrates the declared tools/dependencies and unprivileged runner user; no Docker/sudo parity claim.
- Base inspection rejects unknown recipe/version/digest and moving unpinned acquisition; image metadata is sufficient to reproduce or explain an unavailable upstream input.

## Required implementation/testing work

- Recipe/manifest validation, missing/mismatched inputs, build timeout/failed provision/failed shutdown and atomic-promotion negative tests.
- A bounded real disposable image build plus offline secret/identity inspection, with exact source/tool/image evidence and cleanup.
- Retained sanitize regressions and fresh-boot identity controls; keep fixture keys synthetic and never export a credentialed disk.

Also run `python scripts/check_repository.py` and `python -m unittest discover -s tests -p "test_*.py"`. From RUNLOC-001 onward run the consolidated `python scripts/check.py` and the issue's focused tests. All commands must target the intended checkout. Normal PR checks must require no VM/API credentials; separate physical/live acceptance is required only where specified and cannot be replaced by a mocked or all-skipped pass.

## Excluded scope

No registered runner, GitHub job, persistent developer profile, Windows media or broad hosted-image equivalence.

## PR, automated checks and autonomous merge

Commit only clean intended source/tests/docs. Push a PR containing `Closes #<this issue number>`, a concise behavior summary, actual test/evidence links, limitations and RAG updates. Do not close this issue through a partial implementation. Inspect final diff and resolve material review findings. Wait for **all actual required automated checks on the exact PR head**, with about 120-second polling intervals. Fix relevant failures; do not disable checks or merge known-red work.

When dependencies and every acceptance clause are satisfied, required checks are green, review threads are resolved and no owner hold exists, squash-merge using the exact expected head. Do not use admin overrides or weaken branch protection. Verify the resulting main and post-merge checks, then add a factual completion comment with source/evidence and update programme status. If post-merge acceptance fails, reopen the issue and repair it.

If permissions, required review, approved hardware, credentials or another binding prerequisite is unavailable, preserve a reviewable draft PR and exact blocker. Never enroll credentials, change host privileges, fake physical acceptance or declare a merge that did not happen. A documented no-go completes a research issue only when its acceptance criteria explicitly allow it.

Canonical scope: [issues.json](https://github.com/techrote/runloc/blob/main/docs/programme/issues.json); repository mirror: [RUNLOC-005.md](https://github.com/techrote/runloc/blob/main/docs/programme/issues/RUNLOC-005.md).
