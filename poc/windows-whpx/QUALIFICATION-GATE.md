# Source-bound CI-PoC003 coordinator

This is a manually opted-in native Windows coordinator for the exact candidate
and definitions in `gate-policy.json`. A different EzVM head cannot inherit its
result. The approved 002 host controller, private workflow, job controller and
original full release scenario remain unchanged. WHPX uses six vCPUs per guest;
original memory and operation limits remain in force. Hosted TCG starts first,
independently, with no dependency on private capacity.

From a clean pinned Runloc checkout, run `Open-QualificationGate.ps1` in a dedicated
PowerShell process, passing `BackingRoot`, `ExpectedControllerCommit`, and the
qualified `PrivateControllerRoot`. The opener creates a private DACL state folder
and launches an Explorer-owned console. Python runs with `-B` so source validation
does not create its own bytecode dirt. The private runner has a second independent
console with phase telemetry and host resource metrics. Keep both consoles and
the PC running. Closing Codex does not own either console's process lifetime.

Use `ResumeState` with the same durable state to resume observation. An uncertain
dispatch/start is never replayed. State locking excludes duplicate observers of
one comparison; a shared backing publication lock serializes the candidate status
and quarantine decision. The unchanged private supervisor enforces its 600-second
queue deadline and cancels only its exact associated private run during cleanup.
No private conclusion cancels the independent hosted run.

Only a complete validated WHPX receipt can accept while hosted remains pending.
Hosted success can accept after a positive private infrastructure decision or an
explicit `hosted-only` rollback; private pending remains pending. Functional,
source, security, cleanup and unknown failures dominate either lane's success.
The hosted observer continues after early WHPX acceptance. A late hosted failure
revokes success and writes a persistent, fsynced quarantine record. New green
evidence cannot clear that record; recovery requires explicit reviewed action.

The status context is `EzVM qualification / source-bound`, on the exact candidate
commit. It links to an author-bound issue ledger comment and includes that comment
body's SHA256. Comments are mutable: the coordinator's `--verify-for-merge --state`
mode refetches and validates the current comment, latest owned status ID, actual
run/job identities, original artifact transport digests and complete receipts.
It never grants acceptance from a check name or a raw PASS string.

`loss-before-harness` is an opt-in fault control. It requests stop on the exact
owned lease after dispatch. Infrastructure classification requires one explicitly
skipped full-scenario step with no failing step, complete disposal and registration
absence. Missing or partial steps are unknown, not proof of a safe fallback.

This host-side observer is not an independent cloud service. Hosted execution
continues if the PC goes offline, but publication/revocation can wait for observer
restart. A completed merge cannot be undone by a later diagnostic failure. The
merge verifier can verify early WHPX acceptance while continuing hosted observation;
issue closeout also requires the actual hosted comparison and fallback controls.
Branch-rule migration and future unapproved-source behavior must be documented
and tested in EzVM before CI-POC003 completion. Existing legacy hosted deferral is
still pending replacement; this file alone does not complete issue23.

`absent-capacity` is a separate opt-in control for an absent eligible runner,
not a claim that the physical PC is offline. It allocates a fresh UUID label,
positively checks the complete repository runner inventory for both matching
names and labels, and dispatches the unchanged qualification workflow without
requesting any registration. The exact associated job must remain queued with
runner ID0 and no executed steps for the600second queue interval. Only that
owned run is then cancelled; terminal cancelled/no-runner/no-step evidence and
a fresh complete inventory are required before the decision becomes `absent`.
An assigned runner, executed step, unexpected conclusion, incomplete inventory,
API error or premature cancellation cannot grant fallback. Ambiguous dispatch
uses the original durable intent, and merge verification refetches the evidence.
The existing quarantine still blocks this control from accepting; this addition
is software coverage until its fresh live Actions proof is recorded.

For guest-failure diagnosis, `Open-GuestDiagnostic.ps1` starts a separate
Explorer-owned, private-lease invocation without registering a GitHub runner.
Its hash-bound plan selects `basic-clones` or `release-order`. The latter
restarts a source with synthetic persistence files, snapshots and exports/imports
it, boots the fresh clone, resets and boots the source, then boots the saved
stateful clone and imported instance. Persistence must survive in the stateful
and imported instances and be absent from the fresh/reset instances. This
isolates the intervening operations in the failed full scenario; it omits other
release assertions and can never qualify a candidate. The receipt always says
`diagnosticOnly=true` and `qualificationPassed=false` and binds the scenario.
Both modes retain the six-CPU proof, 900-second READY and 2400-second base-build
bounds, 120-second planned stop and 30-second final cleanup attempts, native
process ownership, independent cleanup/source checks and a diagnostic one-hour
containment wall. Failed fixtures remain private forensic quarantine, never a
reusable qualified artifact or successful fixture-disposal result. A passing
diagnostic does not clear the production gate's persistent failure quarantine.

The explicit `-Scenario full-forensic` mode instead invokes the unchanged
candidate's original `Invoke-EzVm010RealPortability.ps1 -ReleaseQualification`
workload under the same private native Job. Exact ACL preflight must pass before
that workload starts. It requests six CPUs, preserves original memory,
assertions and per-operation limits, and retains complete phase telemetry.
This mode alone uses the owner's NoOverallTimeout policy; both focused modes
retain their one-hour wall. Console workload events are newly drained records,
not repeated log tails. Successful execution additionally requires every original
completion marker exactly once and complete telemetry before fixture disposal.
Failed fixtures stay private for forensic inspection only after owned processes
are positively proven zero; an unknown process count permits no disk inspection.

This is a direct-host troubleshooting run: no JIT runner registration, Actions
ancestry, gate publication, latch recovery or automatic retry. Even a successful
full workload receipt always says `qualificationPassed=false` and
`actionsAssociation=none-diagnostic-only`. It cannot substitute for the real
Actions acceptance required by CI-POC003 or establish the original crash cause.
