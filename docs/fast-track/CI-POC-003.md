# CI-POC-003 — Make qualified WHPX results unblock CI with hosted fallback

**Urgent Windows CI proof of concept. Status: planned.** Creating this issue is not implementation or qualification.

## Dependencies and autonomous prompt

Depends on: [CI-POC-002](https://github.com/techrote/runloc/issues/22)

Implement this issue autonomously in the short Windows/WHPX chain. Fetch current Runloc/EzVM main, read this entire live issue/comments, accepted dependencies, linked instructions and overlapping EzVM PRs43/45/46. Use a clean isolated `ci-poc-003-short-name` branch. The owner authorizes the ordinary implementation/test/PR/merge cycle; no routine confirmation is needed. A real external permission or hardware blocker must remain explicit.

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

- Integrate the accepted001/002 helpers as a narrowly scoped EzVM CI PoC. Start hosted TCG independently and use private WHPX only through explicit approved-source opt-in and bounded available capacity; do not depend on RUNLOC-019 or the full product.
- Implement a stable source-bound qualification coordinator/result which can finish on a complete valid private run without waiting for the slow diagnostic lane. Bind candidate, approved definition/harness and real run/job/runner/receipt identities; no raw PASS-artifact acceptance or check-name spoofing.
- Handle offline/busy/unknown host, disappearance after dispatch, private queue TTL, lost POST responses and cancellation with independent hosted fallback. Cancel only an exact owned private attempt; never cancel hosted merely because a private run starts or finishes.
- Make the exact required-versus-diagnostic check policy explicit in EzVM workflows and AGENTS/RAG, including any reviewed settings migration and hosted-only rollback. Inspect current branch rules; do not silently weaken them or use an admin override. Test the concrete migration before activation.


## Observable acceptance

- A second successful automated full-WHPX run on a clean approved candidate produces an accepted exact-source qualification result before hosted completion; record timestamps and actual accepted completion versus the old wait. Optional parallel execution alone is insufficient.
- With the private host absent before dispatch, hosted execution proceeds and supplies the result; with private capacity lost afterwards, queue handling is bounded and cannot strand the gate. A fully offline controller cannot promise immediate cancellation; restart reconciliation is explicit.
- Wrong SHA/definition/harness/profile/runner, replayed receipt, partial logs, failed exit or forged PASS cannot satisfy the gate. Genuine functional assertion failure is surfaced, not hidden by selecting a different green lane. Infrastructure failure can fall back under the documented policy.
- WHPX acceptance is labelled Windows/WHPX, not TCG coverage. Keep hosted TCG logs/failures visible and classified. If policy/permissions do not permit the concrete gate migration, preserve a reviewable PR and keep the issue open rather than claiming the bottleneck is fixed.
- The exact workflow/policy changes are reviewed, merged only with their actual required checks/acceptance satisfied, and verified on main/post-merge. Hosted-only rollback is exercised. No owner VM/patch or other19-issue programme scope is changed.


## Required tests and evidence

- Truth-table/state tests cover hosted/private success, assertion failure, infrastructure failure, offline/busy, vanished runner, queue timeout, cancelled run, permissions/rate limits and ambiguous dispatch. Assert call order/count and exact cancellation IDs.
- Negative controls reject tampered/replayed receipts and mismatched candidate/definition/runner; test both private-fast completion and hosted fallback without a needs dependency on the slow job.
- Live approved GitHub proof: private available, private absent and private disappears after dispatch, plus a deliberately failing assertion path and rollback. Record actual status contexts, source associations, timings and unchanged assertions. Run Runloc/EzVM applicable checks; no new issue prerequisites.

## Excluded scope

No first-green-wins shortcut, hidden failing test, silent required-check removal, mandatory offline self-hosted matrix leg, new autoscaler/product dependency or assertion that Linux runners solved the Windows-only job.

## PR and completion gate

Put minimal helper/tests/docs in Runloc `poc/windows-whpx/`; put EzVM product/workflow fixes in its clean upstream PRs without copying private patches or relicensing source. Link exact upstream candidate SHA and real PR disposition. The accepted frozen-candidate lab dependency is described in the dedicated contract: do not merge red upstream work just to advance this chain.

Run `python scripts/check_repository.py`, `python -m unittest discover -s tests -p "test_*.py"`, focused PoC tests and applicable EzVM tests. The not-yet-implemented full Runloc CLI/harness is not a prerequisite. Normal PR checks never require live credentials or hardware. Physical/API acceptance above must actually happen; no all-skipped or mocked substitute.

Review final diff and real results, retain original red/green evidence, correct material findings and record actual author/reviewer roles. Push a Runloc PR with `Closes #<this tracker>`, source/evidence links, RAG updates and limitations. Merge only after this issue's acceptance, required exact-head automated checks and resolved reviews, using the expected head and no admin override. Monitor checks around120seconds, not tight polling. Verify main/post-merge checks and comment with factual completion evidence; reopen if acceptance fails. Binding missing prerequisites leave a draft and open issue.

The owner asked for this bounded PoC now; this issue does not authorize changes to owner VMs, privileges, GPUs/models, unrelated code or production branch policy beyond its reviewed stated scope. No private runner or pilot is started by publishing this plan.
