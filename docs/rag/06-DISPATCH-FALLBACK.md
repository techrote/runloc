# 06 — Independent dispatch and hosted fallback

## V0.1 comparison mode

`compare` plans two independent workflow runs. Dispatch the ordinary GitHub-hosted
lane first. Only after hosted acceptance is observed, reserve local capacity,
create/ready the disposable runner and dispatch the optional private lane. If local
execution is disabled, full, unsupported, offline, boot-failed or API-unknown, emit
a precise private skip/failure while leaving hosted execution intact. They are not
a mandatory self-hosted matrix or a dependency chain holding the hosted job.

Both lanes bind identical candidate40hex SHA, workload recipe/input identity and
comparison UUID. Their workflow definition refs/SHAs, OS/architecture/profile,
host/tool/image identity and accelerator are recorded independently. TCG versus
WHPX and different guest tool images are different configurations, not pure host
speed or automatically equivalent tests. Cross-OS results are never interchangeable.

GitHub dispatch selects a workflow at a branch/tag ref; the checked-out candidate
is a separate immutable input. Use an approved workflow definition, resolve its
commit and verify the observed run definition identity. Ref movement during dispatch
invalidates private acceptance and triggers exact-run reconciliation/cancellation.
Templates must exist on the repository's default branch as required by GitHub.
Do not execute arbitrary candidate-supplied workflow YAML with runner credentials.

Unique comparison and attempt IDs are visible in run names and inputs. Bind returned
run IDs when the API supplies them; otherwise bounded observation reconciles the
unique intent. Test both documented success response shapes relevant to the pinned
API, not an assumption that every successful dispatch returns an empty204 response.
An ambiguous hosted dispatch is reconciled before proceeding, never blindly retried.

## Offline and cancellation behavior

GitHub's unmatched-runner queue can last24hours; job execution timeout is not a
queue timer. The private attempt has an explicit finite queue budget. If the runner
disappears after dispatch, the controller cancels only its private run, collects
evidence and disposes the lease. It must not cancel the independent hosted run or
another attempt. If the controller/host is gone, hosted still progresses and the
orphan private intent is reconciled on restart; no promise of cancellation while
the entire controller host is offline. Record cancellation uncertainty honestly.

Neither lane automatically cancels the other on first failure or success. Keep
hosted status authoritative during comparison. Adding a fast optional lane alone
does not reduce the merge wait if the hosted check remains required.

## Later gate promotion

RUNLOC-019 is a separate reviewed policy: define one stable required check with
equivalent-workload private acceptance and hosted fallback, exact candidate/recipe/
definition binding, trusted host evidence, finite decision deadlines and explicit
failure semantics. Check-name spoofing or guest-written PASS cannot satisfy it.
Do not change branch protection automatically or implement first-green-wins by
cancelling an unobserved hosted test. The initial programme makes no such promotion.

See [GitHub](05-GITHUB-RUNNERS.md), [evidence](09-METRICS-PERFORMANCE.md),
[testing](08-TESTING-ACCEPTANCE.md).
