# 02 — Windows host and QEMU control

Doctor checks OS/architecture, Python, disk/RAM/CPU headroom, locked tool digests,
WHPX feature availability, host ACL operations, process containment and outbound
GitHub prerequisites. Capability detection is not physical execution proof. Probe
the exact private-key ACL sequence on synthetic files, including existing broad
ACEs; do not require `SeSecurityPrivilege` for ordinary private file permissions.
Fail with remediation before downloads, registration or guest work if unavailable.
Never enable features, elevate, install drivers or change owner VM allocations.

Resolve QEMU from Runloc's verified cache, not an arbitrary executable on PATH.
Build an explicit argument array for `q35`/x64 (qualify exact machine choice),
virtio disk/network, `-accel whpx`, no display, no graphical monitor, a bounded
serial log and QMP over controller-owned stdio. Keep QMP/serial separate and
drain all streams concurrently. Do not expose a QMP TCP socket, SMB/9p/virtiofs
host share or host control web server to the guest.

Initial user-mode NAT supports guest outbound HTTPS and one host-initiated SSH
forward bound exactly127.0.0.1. No bridge, TAP, WSL or public inbound port.
Outbound-only does not constitute LAN/host isolation: the initial trust policy
allows only explicitly approved repository/workflow/candidate code, and documentation
must state residual guest networking access. Hard multi-tenant isolation is not
claimed. Private runner use never follows an arbitrary public PR trigger.

Windows QEMU launch must use a contained, race-safe process relationship (Job
Object with kill-on-last-owner-close, suspended assignment then resume or a proved
equivalent). Containment failure is a preflight failure, not a fallback to killing
a PID. Record executable/root/creation identity; inspect QMP state as additional
evidence. Reused PID, escaped descendant, inherited pipe handle and dead controller
are mandatory tests. Initial runtime process ownership is independent of a shell
pipe; capture-return must not wait for QEMU's entire lifetime.

Stop uses owned QMP graceful shutdown, then a bounded contained termination and
confirmed exit. Never stop all QEMU processes. Hard-killed overlays are tainted and
discarded, not reusable image candidates. If exact ownership cannot be proved,
quarantine and report instead of killing another process or releasing capacity.

WHPX may not silently fall back to TCG. Diagnostics may explicitly select TCG and
record it separately. Physical probes require a fresh synthetic lease and the exact
tested tool/image IDs. QEMU command construction, feature detection and mocked
READY cannot qualify acceleration. Linux process/KVM implementation is017.

See [guest](04-GUEST-CONTRACT.md), [recovery](07-SECURITY-RECOVERY.md),
[acceptance](08-TESTING-ACCEPTANCE.md) and [sources](11-SOURCES.md).
