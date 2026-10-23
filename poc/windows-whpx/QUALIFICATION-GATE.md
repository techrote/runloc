# Source-bound CI-PoC003 coordinator

This is a manually opted-in native Windows coordinator for the exact candidate
and definitions in `gate-policy.json`. A different EzVM head cannot inherit its
result. The reviewed native host and private workflow retain the original full release
scenario and one-job lifecycle. WHPX uses six vCPUs per guest;
original memory and operation limits remain in force. Hosted TCG starts first,
independently, with no dependency on private capacity.

The reviewed definitions are frozen at EzVM `8ed0bdd`, with job controller
`a71e9e1`, native runner host controller `cfea92c`, and exact candidate `b205230`.
The disposable venv optimization retains real offline pip and its90-second bound.
New full physical and hosted qualification is still running; these source pins
alone grant no acceptance. The attempt-specific encrypted forensic definition
is separate from this normal hosted adapter.
The private002 definition remains separately pinned. Updating these
definitions does not recover or supersede the original failed comparison; its
quarantine still blocks acceptance until an explicit reviewed recovery action.

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

Recovery is optional committed policy, not writable observer state. No recovery
record is currently enabled. Its exact candidate/tree, canonical backing-path
digest, legacy-byte digest and
committed adjudication digest must agree; the adjudication binds independently
reviewed physical/hosted proof identities and explicitly retains the unresolved
historical cause. It grants eligibility for a fresh comparison only. Missing,
changed, unreadable or malformed history blocks, including on another backing
directory. The original global latch is retained byte-for-byte, so older
controllers remain blocked.

Every new actual functional, unknown, source, security or cleanup failure is
fsynced into the private backing's `ci-poc-003-failures/<comparison-UUID>.json`
under the publication lock, even when the legacy latch already exists. The first
failure is immutable and repeated observations do not overwrite it. New records
cannot be exempted through legacy recovery. An existing empty store also blocks:
it can be a crash between observing failure and durably writing its record.
Partial or unknown files, malformed
records, hardlinks and reparse points block startup, publication and merge
verification through the same predicate. Failure derived solely from an existing
quarantine does not fabricate another observed workload failure.
If recording fails but retained history already blocks eligibility, publication
still revokes success with a failure-only persistence-error flag; the history is
not repaired or overwritten. If no persistent block can be confirmed, publication
stops with an explicit unresolved-storage failure instead of claiming persistence.
That comparison retains its original failure in durable state. Any unresolved
marker blocks startup and verification after restart; publication retries that
original failure rather than substituting a later green observation. Successful
retry does not clear the comparison's block or its new persistent failure record.

The status context is `EzVM qualification / source-bound`, on the exact candidate
commit. It links to an author-bound issue ledger comment and includes that comment
body's SHA256. Comments are mutable: the coordinator's `--verify-for-merge --state`
mode refetches and validates the current comment, latest owned status ID, actual
run/job identities, original artifact transport digests and complete receipts.
It never grants acceptance from a check name or a raw PASS string.

`loss-before-harness` is an opt-in fault control. It requests stop on the exact
owned lease after dispatch. Loss and queue-expiry infrastructure classifications
require terminal cancelled run/job association, complete disposal and registration
absence. An assigned job must bind the exact owned runner ID/name/UUID label,
uniquely skip the full scenario and have no failed step. An unassigned job must
positively show integer runner ID0, empty runner name, exact UUID label and an
explicit empty steps list. Missing or partial steps are unknown. Non-atomic API
cancellation observations may settle for120seconds after observed controller
exit; they cannot accept, and any observed assertion failure blocks immediately.

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

`Invoke-AssertionControl.ps1` is a separate negative-only hosted Actions adapter.
It requires the trusted owner's first dispatch, exact clean sources and ACL
preflight, then builds a cold TCG guest with six CPUs and the original light
profile's4096MiB. After authenticated READY and CPU verification, it executes
the fixed false guest assertion `test 1 -eq 2`. The actual guest exit must be1;
the harness and Actions job remain failed. Native process ownership, original
base/READY/stop limits, a separate one-hour control wall, unchanged sources and
owned fixture cleanup remain mandatory. This is a focused failure control, not
the full qualification or WHPX coverage. The dedicated receipt always has
`negativeControlOnly=true`, `qualificationPassed=false` and `passed=false`.
Its observed-control field cannot grant success or reset quarantine. Missing,
duplicate or reordered host control records, wrong exits, timeouts, source
changes and unresolved cleanup cannot establish the intended failure control.
Live immutable definition/run/job binding and gate refusal remain outstanding.

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
