# 07 — Trust, credential boundaries and recovery

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
