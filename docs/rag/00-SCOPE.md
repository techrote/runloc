# 00 — Scope and success

## First release

Runloc makes a repository's explicitly approved GitHub Actions job easy to run in
a disposable QEMU VM. The owner selected Linux runners first on17 October 2026;
Windows guests are later. Initial supported target: Windows 11 x64 host + WHPX,
Ubuntu 24.04 LTS Linux x64 guest, Python 3.12 control plane, official GitHub runner.
Exact supported patch versions and digests are selected and locked by RUNLOC-002/005,
not fetched through `latest` during execution. CLI and JSON come before a TUI.

V0.1 is complete only after RUNLOC-001 through014 meet their acceptance, including
real job execution, failure recovery, disposal, a measured WHPX pilot and clean
package reproduction. Follow-ons015–019 do not block that release.

The useful unit is a **lease = one fresh VM + at most one GitHub job**. Immutable
bases may be reused; a guest which has received job/registration material is never
returned to a clean pool. One guest at a time initially. No warm registered runners.

## Non-goals and limits

Not a replacement for GitHub's runner protocol, ARC, Docker, Kubernetes or a general
VM desktop manager. No broad public-fork execution, GPU passthrough, persistent
host service, remote multi-host scheduler or shared host source directory in v0.1.
Container/service actions are unavailable in the base shell-action profile; an
opt-in Docker-in-guest profile needs its own recipe and qualification later.

Linux guests cannot run Windows-only jobs, qualify host WHPX, or substitute for
EzVM's Windows release test. Nested virtualization and Windows images/licensing
are research gates in RUNLOC-016. Linux/KVM host support belongs to017. Other CI
providers may later implement the same narrow runner-provider boundary.

The first comparison mode keeps hosted checks independent and authoritative.
RUNLOC-019 separately decides whether private evidence may satisfy a required gate.
No speedup or equivalent platform coverage is promised from adding a second lane.

## Product and repository boundaries

This is a standalone implementation. Reuse EzVM's observed lessons and review
public contracts, not its private owner patches or assumed redistribution rights.
An EzVM backend may later be proposed as a pinned optional adapter after its API,
licence and qualification are explicit; it is not a prerequisite for v0.1.

Own source/docs use MIT. Do not relicense third-party components. A base-image
recipe is not permission to redistribute the resulting image or Windows media.
Source manifests, notices and download verification are part of the product.

Related contracts: [architecture](01-ARCHITECTURE-STATE.md),
[testing](08-TESTING-ACCEPTANCE.md), [release](10-RELEASE-OPERATIONS.md).
