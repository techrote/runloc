# RUNLOC-006 — Establish authenticated per-lease guest readiness and control

Stage: **v0.1**. Planning status: **planned**. This issue is not implemented by publication of the programme.

## Dependencies and prerequisites

Depends on: [RUNLOC-004](https://github.com/techrote/runloc/issues/4), [RUNLOC-005](https://github.com/techrote/runloc/issues/5)

None beyond accepted dependencies and ordinary local development tools.

Confirm dependency PRs are accepted on current main before coding. Follow-on issues do not block v0.1.

## Autonomous execution prompt

Implement **RUNLOC-006** end to end in `techrote/runloc`. Fetch current main; read this complete live issue and every comment, dependency result, overlapping PR and the linked instructions below. Use an isolated `runloc-006-short-name` branch. The owner authorizes the ordinary implementation, tests, PR and merge cycle under these contracts; routine confirmation is unnecessary. Do not start a later issue or deploy unrelated infrastructure.

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
- [docs/rag/04-GUEST-CONTRACT.md](https://github.com/techrote/runloc/blob/main/docs/rag/04-GUEST-CONTRACT.md)
- [docs/rag/07-SECURITY-RECOVERY.md](https://github.com/techrote/runloc/blob/main/docs/rag/07-SECURITY-RECOVERY.md)
- [docs/rag/09-METRICS-PERFORMANCE.md](https://github.com/techrote/runloc/blob/main/docs/rag/09-METRICS-PERFORMANCE.md)
- [docs/research/EZVM-FIELD-NOTES.md](https://github.com/techrote/runloc/blob/main/docs/research/EZVM-FIELD-NOTES.md)

## Scope to deliver

- Create per-lease seed/SSH identity and a small versioned Linux control wrapper for readiness, configuration, runner status and collection.
- Bind SSH host trust to fresh lease/nonce/image identity through captured bootstrap serial evidence; use isolated known_hosts.
- Transfer sensitive one-use configuration through authenticated stdin/file into mode0600 tmpfs, with bounded operations and redaction.

## Observable acceptance criteria

- Guest readiness requires correct completed provisioning, lease nonce/image, owned QEMU and authenticated channel, not an open port/printed marker.
- Wrong/stale key, nonce, seed or partial provisioning refuses credentials and runner startup.
- No private host SSH/API secret or JIT data appears in serial, argv, base or normal receipt; guest output cannot choose arbitrary host export paths.
- Guest control runs in the documented unprivileged profile and reports precise timeout/transport/command failures.

## Required implementation/testing work

- Stale/forged READY, wrong host key, reboot, partial provision, lost SSH and oversized output negative controls.
- Synthetic-secret inspection across transfer/success/error/collection paths; hostile collection filename cannot write outside lease export.
- Real fresh-guest readiness, fixed control operation and cleanup with separate host/guest evidence.

Also run `python scripts/check_repository.py` and `python -m unittest discover -s tests -p "test_*.py"`. From RUNLOC-001 onward run the consolidated `python scripts/check.py` and the issue's focused tests. All commands must target the intended checkout. Normal PR checks must require no VM/API credentials; separate physical/live acceptance is required only where specified and cannot be replaced by a mocked or all-skipped pass.

## Excluded scope

No GitHub registration, arbitrary interactive terminal injection, trust-on-first-use bypass or host folder mount.

## PR, automated checks and autonomous merge

Commit only clean intended source/tests/docs. Push a PR containing `Closes #<this issue number>`, a concise behavior summary, actual test/evidence links, limitations and RAG updates. Do not close this issue through a partial implementation. Inspect final diff and resolve material review findings. Wait for **all actual required automated checks on the exact PR head**, with about 120-second polling intervals. Fix relevant failures; do not disable checks or merge known-red work.

When dependencies and every acceptance clause are satisfied, required checks are green, review threads are resolved and no owner hold exists, squash-merge using the exact expected head. Do not use admin overrides or weaken branch protection. Verify the resulting main and post-merge checks, then add a factual completion comment with source/evidence and update programme status. If post-merge acceptance fails, reopen the issue and repair it.

If permissions, required review, approved hardware, credentials or another binding prerequisite is unavailable, preserve a reviewable draft PR and exact blocker. Never enroll credentials, change host privileges, fake physical acceptance or declare a merge that did not happen. A documented no-go completes a research issue only when its acceptance criteria explicitly allow it.

Canonical scope: [issues.json](https://github.com/techrote/runloc/blob/main/docs/programme/issues.json); repository mirror: [RUNLOC-006.md](https://github.com/techrote/runloc/blob/main/docs/programme/issues/RUNLOC-006.md).
