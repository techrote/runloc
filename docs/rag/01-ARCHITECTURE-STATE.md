# 01 — Architecture and durable state

## Components and intended commands

Python 3.12 host package `src/runloc/`: `config`, `state`, `artifacts`, `images`,
`leases`, `qemu`, `guest`, `github`, `supervisor`, `evidence`, `dispatch`, `cli`.
Adapters accept argument arrays, deadlines, clocks and injected API/process/file
boundaries. Do not implement GitHub's runner internals. No mandatory third-party
Python package before its value, version and test coverage are documented.

Planned command families: `doctor`, `tools fetch`, `image build/inspect`, `plan`,
`run`, `status`, `stop`, `reconcile`, `logs`, `stats`, `compare`, `evidence export`.
Mutations support a real preview with exact scope and resource budget. `run` is a
foreground supervisor; optional later queue mode runs foreground too. No hidden
daemon or persistent runner registration. Machine output has `schema_version`,
stable error code and redacted detail. Exit0 means requested operation succeeded;
exit 2 is invalid input,3 unavailable prerequisite,4 deadline,5 runtime failure,
6 recovery/quarantine required. Pending/unknown is never encoded as success.

## Lease identity

Lease UUID, host instance UUID, random runner name/unique label, repository,
candidate40hex SHA, approved workflow definition identity, attempt/comparison UUID,
image/tool/runner recipe digests, resource reservation, deadlines and UTC timestamps.
Persist QEMU executable digest, PID plus creation identity, owned process handle
relationship and root; persist API runner/run/job IDs only after observation.
Never put a token/JIT blob/private key in the durable lease or event journal.

Runtime root is explicitly selected; paths within state are relative. Resolve real
paths and refuse junction/symlink escapes for managed state. Versioned JSON files,
atomic replace + flush and OS-backed cross-process locking are enough for v0.1.
Reject unsupported schema versions rather than guessing. Keep monotonic elapsed
time separate from UTC correlation time; clock rollback cannot extend deadlines.

## Transitions

`PLANNED -> RESERVED -> CREATED -> BOOTING -> GUEST_READY -> REGISTERING ->
RUNNER_READY -> DISPATCHED -> RUNNING -> COLLECTING -> DISPOSING -> DISPOSED`.
Any active state can enter `FAILED` or `CANCELLING`, then disposal; ambiguous
ownership/evidence enters `QUARANTINED`. Failure cause is orthogonal to disposal
state: a failed job with complete cleanup is not a successful job. `DISPOSED`
requires local process/storage/secret removal and known registration disposition;
offline API cleanup remains explicit pending remote cleanup. Do not overwrite the
original failure with cleanup success.

Each external write is journalled as intent then observed outcome. Restarting
reconciles actual process/storage/API state; it never repeats a POST or deletes an
unknown directory solely because the previous call timed out. A completed lease
cannot re-register, re-dispatch or boot again.

Initial defaults:2vCPU,4GiB RAM,32GiB guest disk; reserve at least 2logical CPUs,
4GiB host RAM and8GiB physical free storage outside committed leases. Operator
may configure values; validate against actual available resources, sparse-disk
physical usage and quotas. No automatic VM/host resource changes.

Default phase budgets: boot300s, runner-online120s, queue300s, job1800s,
collection60s, graceful stop30s, forced-stop confirmation10s, cleanup120s.
Plan prints a finite total wall budget including retries, chosen before starting.
Operator overrides must remain finite and recorded. No retry resets a phase clock.

See [host](02-HOST-QEMU.md), [storage](03-IMAGES-STORAGE.md),
[GitHub](05-GITHUB-RUNNERS.md) and [recovery](07-SECURITY-RECOVERY.md).
