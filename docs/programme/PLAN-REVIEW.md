# Plan review and revisions — 17 October 2026

This is a primary-agent self-review of the initial draft, followed by a contract
consistency review. It is not represented as independent review or runtime testing.
The owner confirmed Linux runners first, Windows guests later, and asked for the
straightforward licence choice; MIT is used for Runloc's own work.

## Changes made before publication

| Finding in the draft | Improvement | Verification owner |
|---|---|---|
| Ambiguous host/guest/job matrix could promise Windows CI acceleration from a Linux guest | Windows/WHPX host + Linux guest v0.1; separate Windows feasibility and no nested-WHPX claim | Scope00;012/016 |
| Reusing the developer's EzVM checkout would inherit patches, ACL blockage and unclear reuse terms | Standalone narrow QEMU adapter; no code import or private checkout dependency |001/002/004/013 |
| Ephemeral GitHub registration alone leaves used disks/VMs | Explicit host disposal, remote cleanup obligation and no reuse after JIT/job injection |007/008/011 |
| Controller exit might leave QEMU or a pipe-owning descendant | Windows containment before resume, concurrent drains, identity-aware restart reconciliation |004/011 |
| POST timeout could duplicate jobs/runners | Durable write intent, unique attempt identity, observed IDs and reconciliation before retry |007/010/011 |
| Candidate commit could be confused with mutable workflow ref | Separate definition and candidate identities; detect ref movement |010/019 |
| Online probe cannot prevent a later offline queue | Finite private queue budget; exact-run cancellation and honest controller-offline limitation |008/010/011 |
| JIT secrets can leak into seed/logs/argv and templates can run untrusted PRs | Host-only long-lived auth, authenticated tmpfs staging, redaction probes and manual trusted-source policy |005/006/007 |
| A fast optional lane does not reduce a required hosted wait | Keep comparison mode explicit; separate policy for private-required gate |010/019 |
| Boot-only benchmark hides validation/download/I/O | Cold/warm phase timings and equivalent Linux workload, predeclared targets |009/012 |
| Docker workflows may not work in minimal runner guest | First shell-action profile explicitly lacks Docker/sudo parity |005/006/013 |
| Scope creep could hold a useful first release hostage |001–014 first release;015–019 separately gated extensions | Programme/DAG |
| Agents might merge based on green mocks or unavailable hardware | Exact issue oracles, capability-specific acceptance, real gated issues stay open | All prompts/08/014 |
| Documentation can drift from issue bodies/dependencies | Canonical JSON catalogue, rendered issue mirrors, DAG/link validation and negative tests | Bootstrap CI/001 |
| Initial image/storage/process ordering had a hidden bootstrap cycle |003 storage uses tiny synthetic bases;004 owns process lifecycle;005 then builds real prepared image |003/004/005 |
| A safe stdin transfer could still leak when starting the official runner through argv | Verify the pinned runner's environment-input/clearing path and masking, with job-child inheritance controls |006/007 |

## Second-pass consistency checks

The publication validator checks unique issue IDs/numbers, acyclic backward
dependencies, transitive coverage of all core issues by the release gate, existing
RAG links, non-empty scope/acceptance/tests, complete rendered
autonomous prompts, first-release boundary and local Markdown references. Unit tests
include deliberate broken graphs, missing documents and incomplete prompts. It does
not claim to validate the future runtime architecture or external API availability.

Every issue has a bounded deliverable and excludes later features.001 establishes
the product harness; hardware and live API gates are owned explicitly by011/012/014.
015 queueing cannot bypass one-job disposal, and019 cannot change required checks
through an unreviewed side effect. Physical no-go findings keep the first release
open; feasibility follow-ons may complete with an evidenced no-go decision.

Remaining risks are implementation work: correct Windows containment/DACL behavior,
reproducible image inputs, GitHub permissions, refresh of external references and
actual performance. No image, VM or runner has been provisioned by this planning PR.
