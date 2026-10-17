# Immediate Windows/WHPX CI proof of concept

Requested 17 October 2026: a **three-issue fast track**, independent of RUNLOC-001–019.
The Linux-first disposable-VM product is unchanged. This planning task deploys nothing.

## Immediate outcome and scoped exception

Use the existing EzVM full WHPX harness and an on-demand **native Windows runner**
to address its current Windows CI bottleneck. The test's QEMU guests are disposable;
the Windows host is not a disposable VM. This PoC is not Runloc's Linux product,
Windows guest support or nested WHPX. No full CLI, image builder or pool is required.

1. Repair clean-source prerequisites and finish a timed full WHPX qualification.
2. Repeat it as a real one-job GitHub Windows runner execution, then deregister.
3. Accept qualified private evidence promptly through a reviewed CI gate, with
   independent hosted fallback/comparison and tested hosted-only rollback.

Adding an optional job while every merge still waits for the slow check is incomplete.

## Evidence and reviewed starting material

- [EzVM PR46](https://github.com/techrote/ezvm/pull/46), observed head
  `26c61967e91a008082ebc197f16dd94b943ad27c`, has explicit accelerator selection,
  exact ACL preflight, timed receipts and dispatch tests. It is draft/unmerged,
  not a qualified implementation. Reconcile its live head before reuse.
- The first clean attempt passed verified QEMU bootstrap but stopped after422.83s
  in image checks, before a guest. Corrected preflight blocked in0.62s with
  `vmQualificationStarted=false`. Neither establishes WHPX speed.
- The local PowerShell5.1 suite had356PASS/2ACL failures, independently reproduced
  on a synthetic private-key file. Repair standard-user DACL handling without
  SeSecurityPrivilege grants, elevation or owner-patch copying.
- [Latest PR46 hosted run](https://github.com/techrote/ezvm/actions/runs/39042709996/job/117425241318)
  failed after about70minutes on authenticated SSH READY after855s, with STOPPING
  cleanup. That is a separate observed failure, not a proven ACL symptom.
- [PR45 captured-start work](https://github.com/techrote/ezvm/pull/45) and
  [PR43 runner selection](https://github.com/techrote/ezvm/pull/43) overlap; do not
  duplicate or merge blindly. Inspect actual code and logs.
- [Original near-three-hour job](https://github.com/techrote/ezvm/actions/runs/39022570303/job/117367136257)
  was cancelled, not a complete passing speed baseline.

Use exact public commits in dedicated clean checkouts. Never use the dirty owner
checkout, original QEMU start-pipe, TRIO/owner VMs or private patches. Public source
and retained synthetic regressions must suffice on another host; local logs are extra.

## Repository and acceptance boundary

All3 trackers and helper/docs/tests live in Runloc (`poc/windows-whpx/` when
implemented). Standalone PowerShell5.1 and versioned JSON suit the short bridge.
EzVM product/workflow/AGENTS/RAG changes go in clean EzVM PRs, not copied or
relicensed into Runloc. No additional prerequisite issues are required.

001 may qualify an explicitly reviewed immutable public EzVM candidate before its
upstream PR merges. Its Runloc helper/docs PR can merge after its own checks and
real acceptance.002/003 consume that frozen candidate, avoiding a circular wait on
the old TCG gate. This is not permission to merge red upstream PRs or call their
unmerged commits main. Record every upstream PR's real disposition.

### Owner-authorized temporary hosted TCG deferral

On **17 October 2026**, the owner explicitly asked to skip the approximately
three-hour automatic hosted TCG qualification until the end of this CI PoC.
EzVM's full hosted TCG job is temporarily deferred for same-repository PR heads
beginning `ci-poc-` and the existing `ezvm-ci-whpx-pilot` branch. A visible notice
records SKIP and unmeasured TCG coverage. Manual dispatch remains available;
other PRs retain their existing qualification policy.

This explicit scheduling exception supersedes waiting for that automatic job on
the scoped CI-PoC PRs. Preserve repository/control-plane checks, both Windows
PowerShell lanes, standard-user ACL regressions and actual physical WHPX acceptance.
Do not turn a deferred check into qualification evidence or discard any previous
failure. No branch-protection change is part of this temporary exception.

**CI-POC-003 must remove this exception and the corresponding EzVM workflow
condition/notice and AGENTS/RAG text, or replace them with its reviewed qualified
WHPX/independent-hosted-fallback policy, before completion.** Exercise hosted-only
rollback and retain TCG coverage as unmeasured until a complete actual run passes.
The deferral does not implement the final gate or satisfy CI-POC-001 acceptance.

## Full qualification and time bounds

Preserve original assertions: real image operations, prepared base, authenticated
READY, concurrent guests, restart, clone/export/import/reset, identities, cold
relocation and complete release markers. No boot-only substitute, disabled assertion,
mutable guest reuse or PASS with failed exit. Requested/observed acceleration must agree.

Record controller/EzVM commit/tree, harness digest, host/PS/QEMU/image identities,
UTC and monotonic phase times, actual exit, complete markers and owned cleanup.
Source changes invalidate evidence. Split acquisition/integrity/image work from boot.
Target a complete local run <=60minutes, with90minute hard wall and exact-owned
graceful/forced cleanup plan before launch. Excess runtime or missing PASS requires
bounded diagnosis/repair and remains open. Warm cache means verified tools/downloads,
not reused mutable guests. Do not compute a completed-workload speedup from a cancelled run.

## Temporary native Windows runner

Use existing authorized host GitHub CLI/App access for short-lived repository
JIT/ephemeral registration. Verify binary version/hash; foreground, one job,
unique name/lease label and isolated job directory. No service, account/privilege,
PATH, driver, GPU/model or owner VM changes. Keep long-lived runner-admin credentials
host-only, outside job files and logs. Do not enroll new credentials silently.

Only explicitly approved same-repository exact EzVM candidates and trusted workflow
definitions execute; no arbitrary fork PR or candidate workflow with private authority.
Single-use registration does not erase/isolate the host account. Clean only owned
registration, runner files and qualification fixtures; prove process exit, API
deregistration and fixture QEMU shutdown separately.

## Effective CI gate and fallback

Start hosted execution independently for the same candidate. Private selection is
opt-in and bounded; ordinary GITHUB_TOKEN is not assumed to have runner-admin access.
Offline/busy/unknown capacity leaves hosted execution available. A disconnect after
dispatch has a finite queue deadline; cancel only the exact private attempt. A dead
host cannot cancel while offline: reconcile on restart and never hold hosted work.

A stable result binds candidate SHA, approved workflow/harness, actual GitHub
run/job/runner IDs and full receipt. A small GitHub-hosted coordinator may observe
independent child runs but cannot `needs` the slow lane before accepting valid
private evidence. Use narrow Actions/status/check permissions; admin registration
material stays on the host. Reconcile lost POST responses before retry, without
duplicate runs or acceptance from raw PASS text.

Infrastructure failure can fall back. A real assertion failure cannot be hidden by
choosing a green run. WHPX PASS proves Windows/WHPX behavior, not TCG runtime support.
Preserve hosted diagnostics and classify actual failures honestly.

003 must document required versus diagnostic checks in EzVM workflows and AGENTS/RAG.
No protection was observed on EzVM main at planning time; re-read live rules. Stage
a concrete reviewed migration, obtaining required authority if rules now require it.
No silent check removal, admin bypass or untrusted host execution. Prove faster
source-bound acceptance and hosted-only rollback or keep the issue open.

## Autonomous implementation and merge contract

Read each complete live issue/comments, this document, sources and overlapping PRs.
Follow [AGENTS](../../AGENTS.md) except these scoped platform/path/dependency
exceptions. Do not start or close the19 main programme issues through this PoC.
Preserve actual author/reviewer roles and append corrections to original evidence.

Run Runloc repository/unit and focused PoC tests; use EzVM's applicable checks too.
Normal PR CI is offline/credential-free. Specified physical/API acceptance needs
real evidence. Reuse unchanged tested-tree physical results for prose-only edits;
still verify post-merge automated checks. No all-skipped or mocked qualification.

Open Runloc PRs with `Closes #<tracker>`, evidence/limits and upstream source links.
EzVM PRs reference the tracker and obey their own required gates. Merge only after
scope-specific acceptance, required exact-head checks and resolved review, using
the expected head; verify main/post-merge. No routine confirmation or red merge.
A binding external blocker leaves a reviewable draft and open issue.

Sources: [GitHub routing/lifetimes](https://docs.github.com/en/actions/reference/runners/self-hosted-runners),
[secure use](https://docs.github.com/en/actions/reference/security/secure-use),
[runner API](https://docs.github.com/en/rest/actions/self-hosted-runners),
[QEMU WHPX](https://www.qemu.org/docs/master/system/whpx.html).
