# Retrieval index and reading order

RAG here means small repository documents an implementer can retrieve by task.
These are normative implementation contracts, not proof of existing features.

Always read [AGENTS](../../AGENTS.md), your complete issue and comments,
[scope](00-SCOPE.md) and [acceptance](08-TESTING-ACCEPTANCE.md). Then read the issue's
explicit list; each document links its adjacent interfaces. The
[programme](../programme/IMPLEMENTATION-PROGRAMME.md) owns ordering and the
[JSON catalogue](../programme/issues.json) owns canonical scope and acceptance.

| Document | Contract |
|---|---|
| [00](00-SCOPE.md) | Goals, target matrix, exclusions and release boundaries |
| [01](01-ARCHITECTURE-STATE.md) | Components, CLI, durable state and lease transitions |
| [02](02-HOST-QEMU.md) | Host prerequisites, process ownership, WHPX and QMP |
| [03](03-IMAGES-STORAGE.md) | Verified tools, immutable images, overlays and capacity |
| [04](04-GUEST-CONTRACT.md) | Linux recipe, readiness, identity and controller channel |
| [05](05-GITHUB-RUNNERS.md) | Auth, JIT lifecycle, job binding and API reconciliation |
| [06](06-DISPATCH-FALLBACK.md) | Hosted-first comparisons, queue races and future gates |
| [07](07-SECURITY-RECOVERY.md) | Trust, credentials, destructive operations and recovery |
| [08](08-TESTING-ACCEPTANCE.md) | CI, real evidence, failure qualification and merge gate |
| [09](09-METRICS-PERFORMANCE.md) | Receipts, terminal monitoring and measurement protocol |
| [10](10-RELEASE-OPERATIONS.md) | Packaging, updates, demos, support and follow-on work |
| [Sources](11-SOURCES.md) | Primary references and verification date |

Known field-test findings and their limitations are in
[research notes](../research/EZVM-FIELD-NOTES.md). Planning corrections and risk-to-test
traceability are in [the review](../programme/PLAN-REVIEW.md).
