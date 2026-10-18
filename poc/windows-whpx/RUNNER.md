# CI-POC-002 one-job Windows runner

The full physical six-vCPU Actions qualification and registration lifecycle
proofs passed on 18 October 2026. See the [retained evidence](../../docs/fast-track/CI-POC-002-EVIDENCE.md#successful-full-qualification-and-lifecycle-closeout--18-october-2026)
for exact executed commits, all receipts, failed attempts and timing limitations.

The backing Windows/WHPX host and the verified official runner archive remain
available for reuse. Each Start allocates a new random128-bit lease, runner
registration, extraction and mutable job workspace. A completed registration is
never restarted. Reuse requires a new registration with a different ID and name.
The host is not an account-isolation boundary: only explicitly reviewed trusted
repository/workflow/candidate code may execute with this ordinary host account.
Host GitHub authorization stays in the existing CLI/keyring; it is not copied
into runner files, workflow secrets, process argv or the runner environment.

The runner executes natively on this physical Windows PC; the EzVM Linux guest
uses six vCPUs through WHPX. GitHub schedules the job and retains evidence; its
hosted workers do not supply this compute. The earlier eight-vCPU attempt was
interrupted before guest startup. On 18 October the owner reduced the next
guest allocation to six; the eight READY observations and all24 assertions are
still required. The frozen candidate's generic resource helper already accepts
six, so its immutable product source need not change for this allocation.

## Independent visible console

Do not start a long qualification as a Codex terminal child. Closing the app
can terminate that process tree before its supervisor persists final cleanup.
Use the Explorer-owned visible console:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File poc/windows-whpx/Open-RunnerConsole.ps1 -Mode Monitor -BackingRoot <private-backing-root>
```

Monitor is read-only and starts no runner, guest or job. For an approved new
monitor of a specific historical attempt, add `-MonitorLeaseId <32-hex-UUID>`;
otherwise the latest lease is selected. This cannot select a lease for Start.
For an approved new
attempt use Mode Start, ExpectedControllerCommit, WorkflowRef and optional
QualificationMode. Start requires clean reviewed immutable source and an
execution-approved workflow pin. Publish and repin the updated job controller
before approving a successor; the old eight-vCPU workflow must not silently be
reused. The current pin selects the reviewed six-vCPU controller.

The opener binds to the existing Explorer desktop COM object; a fresh
Shell.Application's direct ShellExecute is insufficient because it can launch
under its caller. The child independently verifies its direct Explorer parent
before starting anything. A private hash-bound plan contains paths and public
identities, no capability or credentials. A dedicated foreground supervisor
still owns the runner/job descendants with the original native Windows Job.
No service, scheduled task, privilege or host policy is installed or changed.

Leave the independent console open and keep Windows awake and online. Closing
Codex is separate from closing that console, signing out, rebooting or sleeping
the PC. Console closure can interrupt the job and is never a success receipt.
The console shows exact host event state and bounded phase telemetry; recorded
timestamps distinguish retained evidence from live progress.

The console prints a phase event only when its sequence changes. Separate
timestamped heartbeats report current controller/listener/QEMU process counts,
sampled process-tree CPU as a percentage of total host capacity, working set,
read/write rates and free host RAM. Process generations are checked before
sampling; exited processes between samples may be missed. These are diagnostic
observations, never process-ownership or performance qualification proof.
Phase age/open-operation age, completed integrity-check counts/durations,
observed24-marker/eight-READY/eight-CPU-proof counts and explicit guest-start
stage distinguish file validation from actual guest startup. Quiet telemetry
is labelled; stopped historical evidence is explicitly NOT LIVE and is not
reprinted as new progress. Private structured metrics are retained under the
console state directory with a4MiB bound; they are not uploaded with public
receipts. After final cleanup, counts come from the digest-checked retained receipt, with
its actual exit and host elapsed time. Missing receipt details are unavailable,
not zero progress. A final event alone does not prove process cleanup.
A partial write/read failure cannot cancel or qualify the controller.

The opt-in interactive desktop test is separate from ordinary headless CI:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File poc/windows-whpx/Test-RunnerConsole.ps1 -EvidenceParent <private-existing-directory>
```

It registers no runner and starts no VM. It terminates the launching process's
owned Windows Job, proves the Explorer-owned probe keeps advancing its
heartbeat, then requests and confirms its clean bounded exit.

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
and six CPUs in every disposable qualification profile and the copied builder
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
