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
