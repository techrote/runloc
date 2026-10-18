# CI-POC-002 one-job Windows runner

Implementation is in progress. No registration or real Actions qualification is
claimed by these files or their offline tests. Issue21 remains qualified on its
historical exact sources. Issue22 consumes that work and requires new real
run/job/runner and cleanup evidence before completion.

The backing Windows/WHPX host and the verified official runner archive remain
available for reuse. Each Start allocates a new random128-bit lease, runner
registration, extraction and mutable job workspace. A completed registration is
never restarted. Reuse requires a new registration with a different ID and name.
The host is not an account-isolation boundary: only explicitly reviewed trusted
repository/workflow/candidate code may execute with this ordinary host account.
Host GitHub authorization stays in the existing CLI/keyring; it is not copied
into runner files, workflow secrets, process argv or the runner environment.

`Invoke-OneJobRunner.ps1` provides Start, Status, Stop and Reconcile. Start is
foreground; the owned Windows Job contains the listener and every job descendant
without breakaway. Stop creates an exact-lease request observed by that owner;
it never kills processes by name or guessedPID. Reconcile requires the old lock
to be released, removes only the exact owned remote registration and retains
uncertain local material for ownership audit. Neither command replays execution.

Start requires a clean reviewed public Runloc commit, the pinned official Windows
x64 runner version/size/hash, and a reviewed workflow hash. Resolve an immutable
workflow tag `ci-poc-002-<40-character-workflow-commit>` first, then hash the
definition at that exact commit. Dispatch only the approved manual workflow
using its single UUID label. Generic self-hosted/Windows labels are omitted so
ordinary generic jobs cannot select this registration. A JIT ephemeral setting
and `run --once` provide separate single-job controls; acceptance also requires
actual API association, process exit, deregistration404 and a second-job probe.

The JIT capability is passed only through the native child's startup environment
using the official runner's `ACTIONS_RUNNER_INPUT_JITCONFIG`. The pinned runner
masks and consumes that variable before running jobs. Runloc validates the
allowlisted JIT files, runnerID/name, ephemeral flag and owned work-folder, and
disables executable auto-update. The archive/version must be reviewed again
before moving to a different runner. No service or privilege change is used.

The job clones the exact manifest candidate and executes the reviewed outer
supervisor in separate dedicated processes, first exact preflight and then the
complete original scenario. It selects `-NoOverallTimeout` in both invocations
and eight CPUs in every disposable qualification profile and the copied builder
recipe. All original memory/profile assertions, per-operation bounds, markers,
identity/source checks and normal cleanup remain required. The Actions workflow
removes its former90-minute setting; GitHub's own default job cancellation limit
(currently360minutes) still exists independently of Runloc's disabled overall
timer/target. No unlimited GitHub service lifetime is claimed.

Only named allowlisted receipts/digests/phase events and the Actions association
are uploaded. Raw runner/guest logs, leases, keys, tokens and disks remain private.
The host separately preserves bounded named diagnostics before removing the
workspace. Qualification ownership records live outside runner `_temp`, whose
automatic cleanup would otherwise destroy the external-fixture recovery proof.
After proven outerJob emptiness, each nested external qualification fixture is
checked against its lease, creation proof and exact source pins before removal.
Uncertainty quarantines storage and fails acceptance; an earlier releasePASS
cannot override it. Evidence-write failures must not prevent remote cleanup.

Offline tests:

```powershell
powershell.exe -NoProfile -NonInteractive -File poc/windows-whpx/Test-Pilot.ps1
powershell.exe -NoProfile -NonInteractive -File poc/windows-whpx/Test-Runner.ps1
```

Sources: [official runner command settings](https://github.com/actions/runner/blob/v2.337.0/src/Runner.Listener/CommandSettings.cs),
[GitHub runner API](https://docs.github.com/en/rest/actions/self-hosted-runners),
[workflow dispatch API](https://docs.github.com/en/rest/actions/workflows#create-a-workflow-dispatch-event),
[workflow job timeout](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idtimeout-minutes).
