# 03 — Tools, images, overlays and space

## Reproducible inputs

Commit manifest schemas and small reviewed locks: version, provider URL, architecture,
SHA256, compressed/unpacked bounds, recipe digest and third-party notice reference.
QEMU Windows provider, Ubuntu 24.04 cloud image, official runner archive and guest
packages must be concrete verified inputs selected by002/005. A moving source URL
alone is not reproducibility. Check download status, redirect policy, size, digest,
archive members and extraction root before execution. Interrupted downloads are
temporary and atomically promoted only after verification. Offline verified-cache
operation and digest mismatch refusal are required.

No global installer invocation or PATH changes. QEMU is extracted/managed locally.
Package updates in the guest require a recorded snapshot/version policy; an image
recipe that runs unbounded `apt upgrade` against moving repositories is not exact
rebuild evidence. Track image creation toolchain and resulting digest as well as recipe.

## Prepared Linux base

Minimal Ubuntu 24.04 x64, cloud-init, SSH, trust store and official runner dependencies;
unprivileged `runner` user, shell-action build tools explicitly listed in recipe.
Do not pretend to reproduce all of GitHub's hosted Ubuntu tool image. Base contains
no runner registration, repository checkout, controller/private/host keys, machine
identity reused by leases, job results or personal credentials. Guest SSH host keys
and machine identity regenerate on fresh boot. Qualify the sanitize step.

Build in its own bounded temporary VM, shut down cleanly, validate and atomically
promote image+manifest. No copy/flatten while running. Baseline can contain the
version-pinned runner application, but not JIT configuration. Image ID binds content,
recipe, architecture and runner version. Rebuild for compatible runner updates;
never silently update a locked image while a job starts.

The image builder uses a bounded one-shot cloud-init/serial build protocol and
the owned QMP lifecycle from004. It does not require the later006 runtime guest
control wrapper or a GitHub registration. This keeps the bootstrap graph acyclic.

## Disposable storage

Exactly one backing level: immutable managed QCOW2 base -> writable lease overlay.
Use explicit formats and relative backing references. Check actual qemu-img metadata,
base identity and chain before launch; paths with spaces, malformed/external chains,
changed base and moved cold roots have tests. A content identity is not a reason to
rehash every QEMU file for every tiny command: use a scoped verified session with
precise invalidation, preserve strict cold verification, and measure validation time.

Seed media is fresh per lease and contains only bootstrap identity/control material,
never long-lived GitHub credentials. A lease disk receiving JIT/job state is sensitive.
After stop, destroy its overlay, seed and temporary SSH identity; no snapshot-to-pool.
Deletion validates absolute owned root, non-reparse paths, lease and process absence.
Bases/artifacts are reference-counted or protected under locks. `gc` is previewable,
stopped-only, age/size-bounded and cannot delete another root or a live base.

Capacity admission reserves real host memory/CPU plus storage margins and tracks
physical sparse-file growth, not only virtual size. ENOSPC during download, image
promotion, journal write and log collection must preserve older valid data and
truthful failure evidence. Retention is finite and operator-visible; no unattended
destruction of diagnostic disks with ambiguous ownership.

See [state](01-ARCHITECTURE-STATE.md), [guest](04-GUEST-CONTRACT.md),
[recovery](07-SECURITY-RECOVERY.md), [performance](09-METRICS-PERFORMANCE.md).
