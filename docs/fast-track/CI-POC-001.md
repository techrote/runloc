# CI-POC-001 — Unblock clean-source ACLs and complete the timed EzVM WHPX pilot

**Urgent Windows CI proof of concept. Status: active.** Creating this issue is not implementation or qualification.

## Dependencies and autonomous prompt

Depends on: None. Start here; the19-issue product programme is not a prerequisite.

Implement this issue autonomously in the short Windows/WHPX chain. Fetch current Runloc/EzVM main, read this entire live issue/comments, accepted dependencies, linked instructions and overlapping EzVM PRs43/45/46. Use a clean isolated `ci-poc-001-short-name` branch. The owner authorizes the ordinary implementation/test/PR/merge cycle; no routine confirmation is needed. A real external permission or hardware blocker must remain explicit.

Do not wait for or implement RUNLOC-001–019. This is an interim native Windows host runner for the existing Windows test; it is not the Linux disposable-VM product. Follow the dedicated contract's platform/path/frozen-candidate exceptions, while keeping all credential, ownership, source/evidence and no-bypass safeguards.

## Required instruction and RAG links

- [AGENTS.md](https://github.com/techrote/runloc/blob/main/AGENTS.md)
- [docs/fast-track/README.md](https://github.com/techrote/runloc/blob/main/docs/fast-track/README.md)
- [docs/fast-track/WINDOWS-WHPX-CI-POC.md](https://github.com/techrote/runloc/blob/main/docs/fast-track/WINDOWS-WHPX-CI-POC.md)
- [docs/rag/07-SECURITY-RECOVERY.md](https://github.com/techrote/runloc/blob/main/docs/rag/07-SECURITY-RECOVERY.md)
- [docs/rag/08-TESTING-ACCEPTANCE.md](https://github.com/techrote/runloc/blob/main/docs/rag/08-TESTING-ACCEPTANCE.md)
- [docs/research/EZVM-FIELD-NOTES.md](https://github.com/techrote/runloc/blob/main/docs/research/EZVM-FIELD-NOTES.md)
- [EzVM current agent instructions](https://github.com/techrote/ezvm/blob/main/AGENTS.md)
- [EzVM testing/CI contract](https://github.com/techrote/ezvm/blob/main/docs/rag/08-TESTING-CI-RELEASE.md)
- [Existing pilot PR46](https://github.com/techrote/ezvm/pull/46)
- [Pinned pilot implementation/evidence contract](https://github.com/techrote/ezvm/blob/26c61967e91a008082ebc197f16dd94b943ad27c/docs/CI-QUALIFICATION-COMPARISON.md)


## Implementation scope

- Inspect current EzVM main and PRs43/45/46 plus their actual failing logs. Reuse the reviewed explicit-accelerator harness from PR46 in a clean pinned checkout. Do not resume the dirty owner checkout or old incomplete fixtures.
- Implement a narrow independently reviewed upstream EzVM private-DACL fix and retained standard-user regressions: preserve confidentiality while avoiding the SeSecurityPrivilege failure. Do not copy owner patches, elevate or grant privileges. Keep the exact synthetic preflight before expensive work.
- Add the minimal standalone PoC invocation/evidence helper and tests under poc/windows-whpx in Runloc. Pin public EzVM candidate/controller/harness identities; this does not require RUNLOC-001 or an installed Runloc product.
- Run the whole original Windows/WHPX release/portability scenario, not a boot smoke. Diagnose and narrowly repair any real subsequent READY/pipe/cleanup/validation blocker, preserving assertions and exact before/after evidence. Profile expensive validation/image work without disabling integrity checks.


## Observable acceptance

- Both existing failing ACL tests and new broad/inherited-ACE regressions prove old failure then fixed standard-user behavior under PowerShell5.1; applicable PS7 and repository checks also pass. Wrong-path/ACL failure still refuses work.
- A fresh clean immutable public candidate completes the full WHPX scenario with exit0, complete original release markers, actual accelerator agreement, unchanged tested source/tree and clean owned fixture shutdown. No unqualified PASS from detection, a single READY or a skipped clause.
- Record all phase times and tool/image/host/source identities. Target <=60minutes with90minute hard wall and owned bounded cleanup; a cancelled or timed-out run is failure, not a speed benchmark. Keep this issue open while any full-run clause or target is unresolved.
- Publish a reusable redacted receipt/evidence set and exact candidate/controller SHA plus upstream PR links/disposition. Its Runloc helper/docs PR is merged after its own checks and actual physical acceptance; upstream EzVM PRs remain subject to their own gates. A frozen reviewed candidate may be used before upstream merge without claiming it is main.


## Required tests and evidence

- Run candidate EzVM scripts/Test-Repository.ps1 and tests/Run-Tests.ps1 in PowerShell5.1 and its supported pinned PS7 lane. Retain exact-source ACL positive/negative controls, no privilege assumption and failed preflight before fixture/download mutation.
- PoC helper tests reject dirty/staged/wrong-SHA source, mismatched accelerator, missing completion markers, failed exit despite PASS text, wrong fixture ownership and stale reused receipts. Use synthetic files/processes; unrelated sentinels must survive cleanup.
- Run one complete cold physical Windows/WHPX qualification with phase/exit/cleanup evidence. Failed attempts remain immutable; source changes require retesting the changed tree. Run Runloc's existing repository/unit checks without credentials in PR CI.

## Excluded scope

No runner registration, host privilege/configuration change, branch-rule bypass, full Runloc implementation, Windows guest/nested-WHPX work or disabled original test. Do not merge the currently red EzVM PR46 merely to unblock the chain.

## PR and completion gate

Put minimal helper/tests/docs in Runloc `poc/windows-whpx/`; put EzVM product/workflow fixes in its clean upstream PRs without copying private patches or relicensing source. Link exact upstream candidate SHA and real PR disposition. The accepted frozen-candidate lab dependency is described in the dedicated contract: do not merge red upstream work just to advance this chain.

Run `python scripts/check_repository.py`, `python -m unittest discover -s tests -p "test_*.py"`, focused PoC tests and applicable EzVM tests. The not-yet-implemented full Runloc CLI/harness is not a prerequisite. Normal PR checks never require live credentials or hardware. Physical/API acceptance above must actually happen; no all-skipped or mocked substitute.

Review final diff and real results, retain original red/green evidence, correct material findings and record actual author/reviewer roles. Push a Runloc PR with `Closes #<this tracker>`, source/evidence links, RAG updates and limitations. Merge only after this issue's acceptance, required exact-head automated checks and resolved reviews, using the expected head and no admin override. Monitor checks around120seconds, not tight polling. Verify main/post-merge checks and comment with factual completion evidence; reopen if acceptance fails. Binding missing prerequisites leave a draft and open issue.

The owner asked for this bounded PoC now; this issue does not authorize changes to owner VMs, privileges, GPUs/models, unrelated code or production branch policy beyond its reviewed stated scope. No private runner or pilot is started by publishing this plan.
