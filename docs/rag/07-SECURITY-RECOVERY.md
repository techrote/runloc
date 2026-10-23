# 07 — Trust, credential boundaries and recovery

CI-POC-002's native host runner follows the separate
[one-job registration boundary](../../poc/windows-whpx/RUNNER.md). The reusable
backing environment persists; runner credentials and mutable job workspaces do
not. JIT startup input is consumed from a closed child environment, never argv.
Cleanup of externally allocated qualification fixtures requires their exact
nested lease/creation proof plus proven emptiness of the containing native Job.
Independent cleanup stages must still deregister when diagnostic writing fails.

## Supported trust model

The owner approves repository, workflow definition, exact candidate SHA and resource
profile. V0.1 permits those trusted runs, not automatic arbitrary public-fork PRs.
Public-repository visibility is not execution authorization. QEMU is a useful VM
boundary, not an asserted escape-proof multi-tenant sandbox. User-mode NAT does
not by itself deny access to the host/LAN. Do not widen claims through marketing.
Normal hosted PR CI uses no controller credentials or private hardware. Never use
pull_request_target plus untrusted checkout to get private-runner authority.

The guest gets only job-scoped GitHub material and its single-use JIT capability,
not the host API credential, global SSH identity, source tree, QMP or management
socket. Guest-result paths/content are untrusted. All serial/runner/job/SSH logs
are bounded and redacted before retention/export; test encoded and multiline
synthetic secrets without pretending arbitrary secret detection is perfect.

## Ownership and disposal

Require lease UUID, canonical owned root, process creation/executable identity and
lock state before any destructive operation. Refuse path escapes, junctions,
symlinks, hardlink ambiguity, base deletion while referenced and cleanup of another
instance. No wildcard process kills or directory removal. Deleting sensitive files
is not guaranteed secure erase on SSD; use host disk protection as an operational
prerequisite where residual storage confidentiality matters.

After any job attempt, preserve bounded diagnostics, stop the owned VM, confirm
exit, delete overlay/seed/control secrets, release capacity only when local
ownership is resolved and reconcile exact remote registration. No used disk goes
back into the image/cache pool. Missing guest logs do not justify retaining a live
runner forever: collection has a finite budget and failure is recorded.

## Recovery matrix

The003 coordinator distinguishes an absent dispatch key from a present malformed
intent. Empty/null/partial intents, inconsistent confirmation states and invalid
run IDs fail closed before any API write; an existing valid unknown intent can
only reconcile. Writable observer state is reloaded after acquiring its exclusive
lock so an earlier unlocked snapshot cannot authorize another POST. The reviewed
assertion-control dispatch wrapper also holds its own exclusive state lock.

Inject controller death at every persisted transition, including API-intent windows.
On Windows the owned Job Object closes QEMU when the supervisor dies. Restart
reconciles remaining files, API objects and reservations; it never replays execution
on a used lease. Explicitly test host reboot, lost network, removed API permission,
runner-online timeout, job cancellation, QEMU crash, reused PID, pipe descendant,
log flood, disk-full and failed atomic writes. Report recovery-required/quarantine
if ownership or remote outcome is unknown.

Remote cleanup pending is visible even after local disposal; do not call the entire
lease fully disposed until obligations are known satisfied. Retry obligations have
backoff/deadlines, preserve evidence and do not authorize infinite unattended work.
Quarantine cannot silently consume unbounded disk or be treated as free capacity.

No testing against owner VMs, real credentials in fixtures, hypervisor escape
experiments or broad network scans. Tests use synthetic disposable roots/processes
and an explicitly approved qualification repository. Security fixes remain narrow,
reviewable and coupled to regression tests.

See [state](01-ARCHITECTURE-STATE.md), [host](02-HOST-QEMU.md),
[storage](03-IMAGES-STORAGE.md), [acceptance](08-TESTING-ACCEPTANCE.md).

## CI-POC-001 native Windows boundary

The separate [Windows PoC](../fast-track/WINDOWS-WHPX-CI-POC.md) invokes an
explicitly reviewed public EzVM commit from a clean checkout. The invocation
controller is also an exact clean Runloc commit. Repository visibility alone is
not approval of a different candidate. The candidate manifest and both source
identities are revalidated; staged/modified source, untracked inputs and reused
attempts cannot produce qualified evidence.

The standalone helper owns only its unique attempt directory and Windows Job
Object. Assignment happens before child execution. The child's temporary paths
are confined to that lease; the original EzVM scenario still creates fresh
source, images and guest fixtures. Existing VMs, credentials and owner checkouts
are outside this boundary. Hardware preflight does not install or enable WHPX.

Synthetic private-file ACL preflight must pass through the exact candidate's
controller-private-key restriction before downloads or qualification fixtures.
It changes only synthetic fixture permissions. Audit/SACL access, elevation and
new privileges are not prerequisites. The upstream repair and its independent
standard-user evidence belong to EzVM; no product source is copied into Runloc.

Raw diagnostics remain private to the attempt. Only a deliberately allowlisted
receipt may be published. Cleanup must separately prove child/descendant exit,
verify the exact owned lease and reject redirected/shared file targets before
disposal. Unknown cleanup stays failed/quarantined. The full release marker is
emitted before upstream finalization, so it cannot override a cleanup or source
restoration failure. A forced or timed-out run remains failure even if cleanup
succeeds. See the [implementation checkpoint](../fast-track/CI-POC-001-EVIDENCE.md).

## CI-PoC003 reviewed eligibility recovery

The original global failure latch is retained unchanged. A source-bound recovery
must be committed with the exact candidate/tree, canonical backing-path digest,
legacy-byte digest and a digest-bound reviewed adjudication. The adjudication
retains the unresolved historical cause and real physical/hosted proof identities.
It permits a fresh comparison to run; it cannot supply its result. No recovery is
currently enabled. Writable observer state cannot enable or broaden recovery.

Each new actual failure is fsynced into a separate immutable comparison record
under the existing publication lock, even if the legacy latch already exists.
Repeated observations preserve the first failure. Any failure-store presence,
including an empty directory left between failure observation and file creation,
blocks eligibility. Unknown/partial files, malformed records, unreadable history,
hardlinks and reparse points fail closed. New records cannot be exempted by the
legacy recovery mechanism; missing required history or another backing path also
blocks. Startup, absent-capacity dispatch, publication and merge verification use
the same predicate. Quarantine-only rejection does not invent another workload
failure. Offline controls exercise real temporary files and injected write faults.
