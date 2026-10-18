# CI-POC-003 implementation checkpoint

## Basic cold-clone diagnostic completed — 18 October 2026 UTC

The [unaltered receipt, closed guest events and digest manifest](evidence/ci-poc-003-basic-clones-2dc2e21f/manifest.json)
record diagnostic lease `2dc2e21fb19546669cf3d71d79b3da89` on controller
`11fa575d356fe9a774df9ec7147b31edb49cc168`, tree
`a3685a66759e57f9e61702e86398d6ae9358e4f2`, and unchanged EzVM candidate
`2268468cb3040b9e1dd6deed60d0f13594f768d6`, tree
`d5677a166e54583f26e3f08e90e5836c19f99359`.
The source and three fresh/stateful clone pairs each reached authenticated
READY with six CPUs and stopped: seven READY proofs and seven stops.
Elapsed2841.232588seconds (47m21.233s), child exit0, no forced termination,
active owned processes0, fixture removed, source unchanged and no cleanup errors.
The receipt SHA256 is
`87b915058e4a471a385d09d15615a78417a275e8098d450c3a8808cca923b2b3`.

This is explicitly diagnostic-only, with `qualificationPassed=false`. It
narrows the basic cold-clone path but does not reproduce every original source
restart/export/import/reset interaction, identify the original guest crash,
qualify the full release scenario or clear the failed comparison's quarantine.
The separately reviewed `release-order` diagnostic and independent full hosted
run39171273724 are still in progress at this checkpoint.

## First real comparison failed — 18 October 2026

[Private run39159455088](https://github.com/techrote/ezvm/actions/runs/39159455088/job/117769490867)
and [independent hosted run39159422984](https://github.com/techrote/ezvm/actions/runs/39159422984/job/117769400541)
both failed. The source-bound coordinator published failure and retained its
persistent quarantine. The [byte-preserved receipts and manifest](evidence/ci-poc-003-416568-failed/manifest.json)
are the original failed attempt, not a successful qualification.

The private run passed exact preflight, reached14/24 completion markers and5/8
authenticated READY/CPU proofs, then its stateful guest's current serial log
reported a kernel panic after PID1 (`systemd`) died with `0x0000008b` on
kernel6.8.0-142-generic. The guest did not become READY or stop gracefully.
Supervised host elapsed6037.8225399seconds, actual controller exit1, final owned
process count0 and fixture removed after forced cleanup. The cause of the guest
crash remains unresolved; no stdio or ACL cause is inferred.

The hosted run passed exact preflight, reached3 READY proofs, then fresh-guest
READY failed. Child exit1, elapsed7484.8456143seconds, forced cleanup, process0,
fixture removed and source unchanged. Its original raw guest diagnostics were
not uploaded, so its underlying cause remains unknown. New hosted evidence must
retain closed-vocabulary diagnostic signals without publishing raw guest/tool
text, paths or credentials.

The restored legacy TCG run39159210774 on EzVM PR54 head8644087 also failed
disposable venv/pip validation. Its generic message does not distinguish an
actual command error from the original90-second deadline. It remains a separate
red result, not evidence that all three failures share a cause. No PR is merged
and issue23 remains open while diagnosis, repair and fresh qualification proceed.

Started 18 October 2026 from live Runloc main
`f29e4facb310f1a0d2da208f50a2416708f8db7f` and EzVM main
`a3c6d3ec4c7506d8f8d1c553eb7a4560ddc61d4d`. Issue22 is completed and closed.
This checkpoint is implementation work, not acceptance or authorization of
unreviewed candidates. Issue23 remains open until all real gate/fallback cases,
final independent review and normal merges pass.

The reusable native Windows backing environment and six-vCPU profile from002
remain the physical target. Frozen candidate
`2268468cb3040b9e1dd6deed60d0f13594f768d6` remains on draft EzVM PR46; it is
not EzVM main. Only its exact SHA/tree may consume its qualification. A workflow
or policy PR does not inherit a different candidate's green status.

The separate hosted adapter retains the original functional scenario under TCG,
all23 functional markers, eight authenticated READY/CPU proofs, exact synthetic
ACL preflight, source and tool/image identity, actual numeric exits, complete
telemetry and owned Job/fixture disposal. It explicitly reports WHPX SKIP.
It does not broaden the physical WHPX/ordinary-user oracle. Hosted platform and
account differences remain explicit. Normal helper CI tests its negative controls
without starting a VM or requiring credentials.

The accepted gate must start hosted execution independently before considering
private capacity. Private PASS needs the original complete oracle plus actual
GitHub association and post-job host cleanup/deregistration. Failure/unknown
classification, queue TTL, ambiguous-write reconciliation, late failure revocation
and persistent quarantine must be tested. Hosted-only rollback and real hosted
fallback remain required. The earlier owner-deferred hosted coverage stays
SKIP/unmeasured until the new actual runs establish their own evidence.

Live EzVM main has no branch protection or rulesets. No enforced required-check
migration exists yet. A source-bound explicit merge policy must validate actual
trusted workflow/API/artifact evidence rather than a check name or mutable target
URL. Any concrete settings change requires its own reviewed and tested migration.

The primary model implements; a separate Extra High model has reviewed the live
contract and initial architecture, with implementation/evidence review still
pending. No previous physical run is claimed as issue23's second automated run.
