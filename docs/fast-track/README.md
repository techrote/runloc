# Immediate EzVM CI fast track

**Three issues; no dependency on the19-issue Runloc product.** Planning only.
The owner requested a small proof of concept to resolve the existing Windows CI
bottleneck now, using the already prepared local WHPX test setup.

Read the [PoC contract](WINDOWS-WHPX-CI-POC.md) and [AGENTS](../../AGENTS.md).

| Issue | Deliverable | Depends on |
|---|---|---|
| [CI-POC-001](https://github.com/techrote/runloc/issues/21) | Unblock clean-source ACLs and complete the timed EzVM WHPX pilot | None |
| [CI-POC-002](https://github.com/techrote/runloc/issues/22) | Run full EzVM qualification on an on-demand one-job Windows runner | CI-POC-001 |
| [CI-POC-003](https://github.com/techrote/runloc/issues/23) | Make qualified WHPX results unblock CI with hosted fallback | CI-POC-002 |

The bridge uses an on-demand one-job **native Windows runner**. Its qualification
QEMU guests are disposable, but the host is not a disposable VM. The main
[Linux-first programme](../programme/IMPLEMENTATION-PROGRAMME.md) remains separate.
The third issue must remove the effective CI wait through an explicit reviewed
gate/fallback policy; adding optional comparisons alone does not complete the PoC.

[Catalogue](issues.json) and adjacent issue mirrors are checked locally and in CI.
No issues are closed and no runner is registered by publishing this chain.
