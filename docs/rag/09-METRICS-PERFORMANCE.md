# 09 — Evidence, terminal stats and measured performance

Versioned JSON receipts plus append-only bounded JSONL events are the interchange.
`stats` displays the same read-only data in a terminal: lease and phase, guest/runner
identity, job/run URL, queue/startup/execution/collection/cleanup elapsed, current
deadlines, CPU/RAM, physical disk usage, reservation/headroom and cleanup obligations.
No full dashboard or input-injected terminal in v0.1. Adapter points allow an EzVM
dashboard to read documented evidence later without coupling these runtimes.

Use stable UTC event timestamps for correlation and monotonic elapsed durations.
Capture host total/per-process CPU carefully with sampling interval and core count;
label unavailable metrics unknown rather than zero. Distinguish guest-claimed values
from host observations and API state, include source and freshness. Monitoring is
not a runner, never writes lifecycle state and cannot keep a lease alive indefinitely.
Bound sample rates, history, output size and retention; monitor failure cannot
change job outcome. Atomic snapshots are read safely while the supervisor updates.

## Qualification timing protocol

Record cold acquisition/extraction/build separately from warm verified-cache startup.
Separate tool/base integrity validation, overlay/seed creation, QEMU boot, guest
readiness, JIT creation, runner online, GitHub queue, workload execution, collection
and disposal. The earlier EzVM pipeline had substantial non-boot cost; don't assume
hardware acceleration fixes hashing/copying/validation overhead.

Predeclare workload recipe, candidate SHA, accepted workflow definition, resource
profile, toolchain, network/cache assumptions and numerical go/no-go thresholds in
the012 qualification plan before its runs. Proposed investigation targets are not
achieved claims. Measure at least 3 cold/warm leases per chosen mode; report all
samples, median and range. Three samples do not justify meaningful p95 claims.

Compare hosted and private Linux jobs at the same source/workload/tool versions.
Record hosted image identity and extra-tool differences; compare assertions/results
as well as time. Wall-time speedup without parity and complete disposal is not
acceptance. Local TCG optional control may isolate accelerator effects, explicitly
labelled and bounded. Windows-hosted TCG numbers from EzVM are background only,
not a Linux Runloc baseline or same-candidate speed comparison.

Qualification go/no-go requires zero false success and leaked/second-job runners,
3/3 clean repeatable leases, successful failure cleanup and a published decision
against the predeclared timing/resource targets. A negative result is useful, but
keeps physical product/release acceptance open until repaired or scope is explicitly
revised. Resource/performance trouble must not cause automatic host tuning.

See [testing](08-TESTING-ACCEPTANCE.md), [research](../research/EZVM-FIELD-NOTES.md),
[sources](11-SOURCES.md).
