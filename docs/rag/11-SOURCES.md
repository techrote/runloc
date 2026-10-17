# 11 — Primary references

Verified during planning on17 October 2026. Implementers must recheck changing API,
runner-version, platform and distribution requirements; source links do not replace
the issue's tests. No external text has higher authority than an explicit local
contract without a reviewed reconciliation. Record material changes in the issue.

| Primary reference | Use and limit |
|---|---|
| [GitHub self-hosted runners](https://docs.github.com/en/actions/reference/runners/self-hosted-runners) | Label routing, queued jobs, platform/profile constraints, ephemeral runners, updates and network requirements |
| [GitHub runner REST API](https://docs.github.com/en/rest/actions/self-hosted-runners) | Repository JIT creation, permission and registration identity; no host-admin token in guest |
| [GitHub workflow REST API](https://docs.github.com/en/rest/actions/workflows#create-a-workflow-dispatch-event) | Workflow ref/input distinction, response run identity and permissions; pin API version and test actual shape |
| [GitHub Actions secure use](https://docs.github.com/en/actions/reference/security/secure-use) | Trusted-source execution, token minimization, workflow dependency review |
| [Official runner releases](https://github.com/actions/runner/releases) | Resolve and verify concrete runner archive/version during implementation; no runtime `latest` |
| [Official runner source](https://github.com/actions/runner) | Supported configuration and behavior, not a licence to invent a runner protocol |
| [Observed runner input handling](https://github.com/actions/runner/blob/v2.338.0/src/Runner.Listener/CommandSettings.cs) | Non-argv JIT input and environment clearing observed during planning; verify masking and child inheritance on the selected runtime |
| [Official scale-set client](https://github.com/actions/scaleset) | Evaluate in018 before inventing autoscaling/protocol machinery |
| [QEMU WHPX](https://www.qemu.org/docs/master/system/whpx.html) | Windows acceleration configuration; capability detection is not execution proof |
| [QEMU invocation](https://www.qemu.org/docs/master/system/invocation.html) | Argument arrays, networking, control/serial channels |
| [QEMU disk images](https://www.qemu.org/docs/master/system/images.html) | Explicit formats and backing relationships; validate the exact pinned tool behavior |
| [Ubuntu cloud images](https://cloud-images.ubuntu.com/) | Concrete release/image and checksum/signature provenance selected by005 |
| [Cloud-init NoCloud](https://docs.cloud-init.io/en/latest/reference/datasources/nocloud.html) | Per-lease bootstrap and instance identity; never long-lived auth in the base |
| [Microsoft Job Objects](https://learn.microsoft.com/en-us/windows/win32/procthread/job-objects) | Windows owned process lifetime and child containment |
| [MIT text](https://opensource.org/license/mit) | Runloc's own permissive licence; third-party terms remain separate |

The runner release observed during planning was2.338.0. That observation is not a
lock or an instruction to use a stale version later.002/005 must resolve and commit
reviewed concrete inputs and the supported update policy before building an image.
