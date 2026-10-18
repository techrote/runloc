# CI-POC-002 — Reuse the Windows/WHPX CI artifact with one-job ephemeral runners

**Urgent Windows CI proof of concept. Status: active.** Creating this issue is not implementation or qualification.

## Dependencies and autonomous prompt

Depends on: [CI-POC-001](https://github.com/techrote/runloc/issues/21)

Implement this issue autonomously in the short Windows/WHPX chain. Fetch current Runloc/EzVM main, read this entire live issue/comments, accepted dependencies, linked instructions and overlapping EzVM PRs43/45/46. Use a clean isolated `ci-poc-002-short-name` branch. The owner authorizes the ordinary implementation/test/PR/merge cycle; no routine confirmation is needed. A real external permission or hardware blocker must remain explicit.

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

- Use001's accepted frozen candidate/helper/evidence and its Runloc main merge; do not wait for RUNLOC-001–019 or upstream source PRs still correctly awaiting their gates.
- Retain the reusable qualified Windows/WHPX backing environment and verified artifacts. Create a fresh single-job ephemeral registration and isolated workspace for each trusted execution; completing a job must not destroy the backing environment.
- Implement minimal start/status/stop/reconcile helpers for a pinned verified official native Windows runner, foreground JIT/ephemeral registration, one job, unique repository/name/label and owned working directory. Reuse existing authorized host CLI/App credentials without enrolling or exporting long-lived admin material.
- Add an approved manual-only EzVM private workflow or reconcile PR46's existing one; bind definition and exact candidate SHA/comparison ID. It runs001's full original WHPX harness on the physical Windows host. Do not run it in the Linux TRIO VM or claim Windows host isolation.
- Capture real GitHub run/job/runner identity, full receipt, diagnostics and exact cleanup/deregistration. Keep workflows/helpers small; no service, webhook daemon, image builder, fleet or scheduler.


## Observable acceptance

- A real GitHub job executes the full original scenario on the approved exact candidate using physical WHPX and eight CPUs, with matching preflight/controller/receipt NoOverallTimeout policy, actual successful exit and complete public run/job/runner evidence. The owner removed the former overall timing bounds for CI-POC-002; keep all original per-operation limits and record elapsed time. GitHub service limits remain external limitations.
- Registration is genuinely single-job; the used runner cannot take a second job. Runner process exits, exact registration is removed, owned qualification QEMU guests stop and owned sensitive working material is removed. Do not erase unrelated host data or pretend the host OS is disposed.
- Only approved same-repository exact candidates and trusted definitions can use the host. No automatic fork execution, service installation, privilege/account/driver changes or admin token in job files, workflow secrets/argv/logs.
- Failed/cancelled job, no-job timeout, lost registration response, startup error and API cleanup failure have bounded truthful outcomes. Remote uncertainty remains explicit and cannot yield a clean-success receipt. Normal PR CI never registers a runner.
- After the first runner is removed, prove backing-environment reuse with a fresh different runner registration and bounded trusted probe. Independently show the used old registration cannot accept a second job; a second full WHPX run is not required solely for this reuse proof.


## Required tests and evidence

- Stub/injected tests assert binary hash/version checks, unique labels, at-most-one job, lost-POST reconciliation, exact-ID cleanup, rate/permission failures, TTL expiry and owned-process/path sentinels. Use synthetic secrets to inspect all logs/error/export paths.
- Perform a real trusted GitHub full-WHPX run and capture API association plus host completion/disposal evidence. Then exercise a failed/cancelled or no-job case and show deregistration/cleanup without affecting unrelated VMs/runners.
- Verify the second-job prohibition independently, not from the --ephemeral flag alone. Run existing Runloc checks and focused helper tests; inspect applicable EzVM workflow/source checks on the exact head.
- Inject missing/incorrect JIT identity and ephemeral policy, external nested-fixture ownership, process-exit uncertainty and preserved backing/sentinel controls. Retain a real no-job or failed/cancelled lifecycle and exact deregistration evidence. Do not replace a single-job registration with a multi-job workflow runner.

## Excluded scope

No permanent GitHub runner registration, global host installation, service or privilege changes, arbitrary public PR execution, or native Windows-as-disposable-VM claim. Preserve the reusable backing environment. Hosted TCG remains deferred under CI-POC-003; no CI gate migration is implemented here.

## PR and completion gate

Put minimal helper/tests/docs in Runloc `poc/windows-whpx/`; put EzVM product/workflow fixes in its clean upstream PRs without copying private patches or relicensing source. Link exact upstream candidate SHA and real PR disposition. The accepted frozen-candidate lab dependency is described in the dedicated contract: do not merge red upstream work just to advance this chain.

Run `python scripts/check_repository.py`, `python -m unittest discover -s tests -p "test_*.py"`, focused PoC tests and applicable EzVM tests. The not-yet-implemented full Runloc CLI/harness is not a prerequisite. Normal PR checks never require live credentials or hardware. Physical/API acceptance above must actually happen; no all-skipped or mocked substitute.

Review final diff and real results, retain original red/green evidence, correct material findings and record actual author/reviewer roles. Push a Runloc PR with `Closes #<this tracker>`, source/evidence links, RAG updates and limitations. Merge only after this issue's acceptance, required exact-head automated checks and resolved reviews, using the expected head and no admin override. Monitor checks around120seconds, not tight polling. Verify main/post-merge checks and comment with factual completion evidence; reopen if acceptance fails. Binding missing prerequisites leave a draft and open issue.

The owner asked for this bounded PoC now; this issue does not authorize changes to owner VMs, privileges, GPUs/models, unrelated code or production branch policy beyond its reviewed stated scope. No private runner or pilot is started by publishing this plan.
