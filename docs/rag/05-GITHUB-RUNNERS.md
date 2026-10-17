# 05 — GitHub authentication and one-job registration

## Boundary

Use the official runner application and documented repository-scoped JIT API.
Single-job registration is not VM disposal; both need independently observed
completion. No organization-wide registration, permanent host runner or runner
protocol reimplementation in v0.1. Keep API base/version and response fixtures
explicit. Recheck current official API documentation during007 implementation.

Long-lived authorization stays in the host credential provider: an existing host
GitHub CLI session or explicitly configured GitHub App/OS secret store. Never
automatically enroll a token or copy a host credential file into a guest. JIT
creation needs repository administration permission; workflow dispatch/cancellation
needs Actions write; read observations and optional future Checks write are separate
capabilities. Ordinary workflow GITHUB_TOKEN is not assumed to grant runner admin.
Permission failure is a precise blocker, not permission to broaden scopes silently.

JIT configuration is a short-lived sensitive capability, regardless of encoding.
Acquire it only for a ready owned guest, pass through the authenticated guest
channel without argv/logging, remove plaintext staging, record only runner ID and
non-secret identity. Test synthetic secrets in success/error/retry/collection logs.
No credential/JIT provider is called by normal unit or pull-request CI.

## Job binding

Generate a unique runner name and custom label per lease and attempt. Templates
require Linux/X64, `runloc` and that lease label; no generic self-hosted-only job.
Verify actual returned labels, runner ID/name and repository, then correlate job ID,
workflow run ID/attempt, approved definition, candidate SHA and assigned runner.
JIT's at-most-one-job property is necessary but does not target a particular job by
itself. Repository/workflow allowlists, unique labels and run association complete
the initial trusted-use contract. A second job must not execute on the used VM.

## API outcomes and cleanup

Write intents before POST. Handle success with documented response IDs, accepted
but lost response, timeout,429/Retry-After,401/403,404,409,5xx, pagination and stale
observations. Reconcile by lease-owned unique identity before a retry; never create
two runners or workflows because a POST timed out. Persist IDs once observed.

Online state is necessary, not proof of job acceptance or completion. Poll within
finite phase budgets and honor rate-limit/backoff hints. Distinguish job failure,
cancellation, queue expiry, infrastructure error and unknown outcome. Runner exit
without a correlated GitHub conclusion is not success. Server deregistration,
explicit exact-ID removal and remote cleanup pending are separate recorded states.

Before deletion, require the stored repo/runner ID and observed unique ownership;
never delete similarly named runners by prefix. A network failure during removal
does not prove absence. Dispose local sensitive VM state even when API cleanup is
pending, retain a bounded reconciliation obligation and never reuse the lease.
Runner-version freshness is part of image readiness; follow GitHub's current update
policy and report a stale image before registration, not an unexplained queue wait.

See [guest](04-GUEST-CONTRACT.md), [dispatch](06-DISPATCH-FALLBACK.md),
[security](07-SECURITY-RECOVERY.md) and [sources](11-SOURCES.md).
