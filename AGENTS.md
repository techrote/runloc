# Autonomous implementation instructions

## Authority and preparation

The current human instruction comes first, then current main, the complete GitHub
issue and comments, this file, its linked RAG contracts and the programme. Fetch
main and read the actual issue/comments, dependencies, overlapping PRs and live CI
before implementation. Never work from a historical handoff alone. Each issue
provides a reusable execution prompt; start at its referenced documents.

The owner's urgent [three-issue Windows CI PoC](docs/fast-track/WINDOWS-WHPX-CI-POC.md)
is a separate fast track. Its native-Windows platform, helper path and reviewed
cross-repository candidate dependency override the product-only assumptions below
for CI-POC-001–003. It does not depend on RUNLOC-001–019 or change their Linux-first
scope. All ownership, evidence and no-bypass rules still apply. The owner's
2026-10-17 temporary hosted-TCG deferral is documented in the fast-track contract;
it expires at CI-POC-003 completion and leaves software/ACL and physical WHPX
acceptance required.

Do not start a dependent issue until its dependencies are merged and accepted on
main. Parallel work is allowed only on independent scope in isolated branches.
Do not duplicate another actor's useful WIP or assume a new agent is required.

## Scope and architecture

- V0.1: Windows 11 x64 host, WHPX, Ubuntu Linux x64 guest, one repository-scoped
  GitHub JIT runner and one job per fresh VM. Python 3.12 host CLI. Other platforms
  are explicit later issues, not implied by cross-platform unit tests.
- These are QEMU VMs, called disposable containers informally. No Docker/OS
  container isolation, Windows guest support or nested-virtualization claim.
- Product code is planned under `src/runloc/`; tests use `unittest`. Prefer the
  standard library and narrow process/API adapters. Explain and pin added packages.
- No local EzVM checkout dependency or copying of unmerged/private code. No licence
  assumptions about other repositories. Do not touch EzVM/TRIO VMs or owner patches.
- Default to one guest, no host service and no permanent registration. QEMU handles,
  storage and API objects are all owned by a durable lease; a PID alone is not ownership.
- No host credential, JIT payload or SSH private key in a reusable base, Git, logs,
  command-line arguments visible to other jobs or published evidence.
- No automatic host privilege, firewall, driver, pagefile or virtualization changes.
  No hardware/GPU passthrough or guest access to controller sockets and host folders.

## Deliver the issue through merge

1. Reconcile current main and the issue. Use `runloc-NNN-short-name` in an isolated
   checkout. Record exact tested commits and actual contributor roles.
2. Implement only its scope plus necessary narrow repairs. Update affected RAG in
   the same PR. New behavior requires meaningful tests, including specified negative
   controls; do not weaken assertions to obtain green output.
3. Run the two README checks and the issue's focused tests. RUNLOC-001 adds the
   consolidated `python scripts/check.py` command for subsequent runtime issues.
   No live VM/API test is allowed in normal PR CI. Required physical acceptance
   uses separate, bounded opt-in qualification, not a mocked PASS.
4. Review the final diff for correctness, source imports, secrets, path ownership,
   provenance and contract coverage. Address every material finding. Record whether
   review was self-review, another person/model, or automated; never invent independence.
5. Commit clean intended paths, push and open a PR containing `Closes #N`, actual
   behavior, tests, evidence, skips/limitations and linked RAG changes. Do not close
   dependencies or unrelated programme issues.
6. Wait for the exact head's required automated checks. Poll about every120seconds,
   perform useful independent work while waiting and inspect actual failing logs.
   Fix relevant failures. Never change checks, skip required acceptance or overwrite
   original evidence merely to make the PR green.
7. Once dependencies and acceptance are satisfied, required automated checks are
   green, review threads are resolved and no owner hold exists, merge the PR with
   squash using an exact expected head. The owner authorizes this routine PR/merge
   cycle for these issues; do not add a routine confirmation step.
8. Verify main contains the change and its post-merge checks pass. Update the issue
   with immutable evidence links/commit and the programme status. Reopen an issue
   closed by the PR if post-merge acceptance fails. Do not claim completion early.

Use existing GitHub authorization or configured App credentials. Do not enroll
credentials, weaken branch rules, bypass approvals or use an admin override. If
permissions, required review or physical capability are unavailable, preserve a
reviewable PR and precise blocker; never claim a merged or qualified result.

## Testing and evidence

`docs/rag/08-TESTING-ACCEPTANCE.md` defines the test layers and failure semantics.
No empty/all-skipped acceptance, invented pass counts, stale logs or success from
tokens, a running process, runner-online status or guest prose. A real job needs
GitHub run/job evidence; disposal needs host process/storage and registration
evidence. A hardware skip is not completion of a hardware-gated issue.

Never retry ambiguous external writes blindly. Observe/reconcile first. Never kill
all QEMU processes or recursively delete a computed path without verifying its
absolute owned root, lease and absence of active users. Preserve bounded redacted
diagnostics before disposal; retained sensitive disks are quarantined and cannot
be reused. External API failure is not evidence that a VM or registration is absent.

Planning issues remain open until their specified implementation/decision is
actually delivered. Updating this documentation is not implementing Runloc.
