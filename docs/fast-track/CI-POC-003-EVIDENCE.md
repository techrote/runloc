# CI-POC-003 implementation checkpoint

## Hosted forensic and legacy timer failures — 21 October 2026 UTC

[Forensic run39505303335/job118912620478](https://github.com/techrote/ezvm/actions/runs/39505303335/job/118912620478)
failed after4944.716207seconds with actual harness exit1. Its original public
receipt, digest and866 retained phase events are preserved with the
[artifact/source association and manifest](evidence/ci-poc-003-hosted-a025e43c-failed/manifest.json).
Base provisioning completed, but the first managed guest panicked before READY:
Linux6.8.0-142, CPU0/PID0, IO-APIC timer validation. Exact preflight exited0;
sources remained unchanged. Outer cleanup was forced, then observed child exit,
owned processes0 and fixture disposal. Incomplete telemetry and forced cleanup
remain failures, regardless of earlier markers.

The separate encrypted artifact was authenticated and decrypted locally; a second
model independently repeated decryption and verified the identical plaintext
SHA256. Raw guest logs and the private recipient key remain private. The
[legacy policy-head job39500448386/118896293651](https://github.com/techrote/ezvm/actions/runs/39500448386/job/118896293651)
shows the same early timer panic on its own source/default resource profile;
it is not a six-core candidate qualification. Both jobs remain failed.

The underlying emulator/timer cause and correction are not yet proven. A focused
six-vCPU default-versus-HPET-off diagnostic preserves APIC and Linux timer
validation; it cannot qualify the full scenario. The older late PID1 crash is a
separate unresolved observation. Quarantine, draft PRs and issue23 remain open.

## Complete fresh Actions WHPX pass; gate remains blocked — 20 October 2026 UTC

[Actions run39491986907/job118867251965](https://github.com/techrote/ezvm/actions/runs/39491986907/job/118867251965)
completed the original full six-vCPU WHPX release/portability scenario. The
[original artifact files, host lifecycle association and manifest](evidence/ci-poc-003-private-a8e37290/manifest.json)
retain24/24 markers,8/8 authenticated READY and six-CPU proofs, actual controller
and harness exits0, unchanged sources, complete2518-record telemetry, unforced
cleanup, owned processes0, fixture disposal, runner48 deregistration verified by
HTTP404, reusable backing preservation and unrelated sentinel survival.

Exact frozen candidate2268468/d5677a1, job controllerd3be2aa/e98d68f and host
controllerf29e4fa/3a7ee51 were used. Whole supervised host elapsed6941.422876seconds
(1h55m41.423s); inner controller elapsed6873.752939seconds. Explicit
NoOverallTimeout was retained, with every original operation/assertion. No former
60-minute performance target is claimed. Both exact preflights exited0 in
1.9080518 and1.1285527seconds, below the frozen controller's original120-second
execution/150-second cleanup bounds. Their nested timeout/cancellation fields
are unavailable; containing-attempt flags are separately recorded, not inferred
as missing nested observations. Both original receipts and their supervisor
chain are bound to this same actual Actions artifact.

The [live assertion-dominance proof](evidence/ci-poc-003-assertion-dominance-a8e37290/manifest.json)
combines this independently validated real WHPX pass with the separately validated
real TCG assertion failure39496444460. The shared decision returns failure in
both argument orders with `quarantined=False` explicitly. The swapped call is a
decision-symmetry control, not another physical lane. No status transition or
quarantine reset is claimed; the original quarantine digest remains unchanged.

This pass did not grant early source-bound acceptance: the independent hosted
recovery had already failed. The separate encrypted forensic run39505303335
and policy-head run39500448386 subsequently failed with an early IO-APIC timer
panic before READY. This is distinct from the older late PID1 crash; neither a
root correction nor gate recovery is claimed. Live available/fallback/loss/rollback
acceptance remains pending. CI-POC-003 is open and the implementation PRs remain
draft. Independent model review verified the original artifact bytes, live API
associations, source fingerprints, lifecycle and assertion composition. The seven
nested failed calls are the original expected refusal controls (existing export
destination, two unsafe imports and four operations against a running source).

## Fresh full hosted recovery failed in base provisioning — 20 October 2026 UTC

[Actions run39491915114/job118866993056](https://github.com/techrote/ezvm/actions/runs/39491915114/job/118866993056)
used immutable hosted workflow1c1dbb68, controllerf167950 and unchanged frozen
candidate2268468/d5677a1. The [original receipt, digest, retained phase
records and manifest](evidence/ci-poc-003-hosted-ebca5084-failed/manifest.json)
record exit1 after4613.1129273seconds (76m53.113s). Exact preflight exit0 and
explicit timeout/cancellation flags false; source unchanged; child exited,
owned processes0 and fixture removed.

Only7/23 functional markers and no authenticated READY were observed. The base
build failed after2486.0099359seconds. Bounded diagnostic reduction observed the
original2400-second provisioning deadline with0 seed requests and a guest kernel
panic in the same base build. This establishes a guest failure before READY;
it does not identify the panic reason or prove the same root cause as an older
stateful guest crash. Raw guest/tool logs were not uploaded. Outer cleanup's
`forced=false` does not prove candidate-internal QEMU cleanup was unforced.

The private recovery and separate policy-head hosted checks were still active
when this record was added. No recovery, source-bound acceptance, merge or issue
completion is claimed. The original persistent quarantine remains unchanged.

## Live negative assertion control observed — 20 October 2026 UTC

[Actions run39496444460](https://github.com/techrote/ezvm/actions/runs/39496444460/job/118882602207)
is an intentional failed functional control. Its [unaltered receipt and digest,
redacted Actions association and manifest](evidence/ci-poc-003-assertion-013a6cfe/manifest.json)
bind comparison `013a6cfef4b448719083b17c9adb9165`, workflow0580dd2/controller1e20cb9
and unchanged frozen candidate2268468. A cold TCG light-profile guest proved
authenticated READY and six CPUs, then the fixed false assertion `test 1 -eq 2`
returned actual guest exit1. Actual harness exit1 and a failed Actions job remain
red; the assertion step was the sole failed step. Preflight exit0 with explicit
false timeout/cancellation flags, unchanged sources, no forced termination,
owned processes0 and fixture disposal all passed. Elapsed884.6739359seconds
(14m44.674s). Receipt SHA256 is
`313322ad189e80aaf0bb2c2ad3c79b2d5727b7e03f662eaf67d8e5560f874f29`.

The strict separate failed-run validator classified the actual receipt as
`assertion`; the shared decision rejects that classification against a symbolic
passing alternative. A separately validated live green alternative is still
pending, so the complete live dominance acceptance is not yet established.
This focused negative-only receipt always denies qualification. It is not the
complete release scenario, WHPX coverage, a historical root fix, quarantine
recovery or issue completion. The immutable negative definition is retained in
draft EzVM57 and must not replace the ordinary hosted workflow.

## Full forensic workload passed — 20 October 2026 UTC

The [unaltered forensic receipt, phase telemetry and digest manifest](evidence/ci-poc-003-full-forensic-7aa570a0/manifest.json)
record lease `7aa570a051924fdc8d03fd3f42a2ccff` executing the original complete
release/portability workload under WHPX with six guest CPUs. Controller
`f167950a865df3baad247ba37ff53f0fcb683a72`, tree
`2d0eb3c68a6ad507c53fbb2af620dec57c3315eb`, and candidate
`2268468cb3040b9e1dd6deed60d0f13594f768d6`, tree
`d5677a166e54583f26e3f08e90e5836c19f99359`, were clean and unchanged before/after.
Independent review and all four exact-head software checks passed before launch.

Exact ACL preflight exited0 without timeout/cancellation. The full child exited0;
all24 required completion markers occurred exactly once, with8 authenticated
READY responses and8 six-CPU proofs. Complete telemetry retains2482 records and
SHA256 `c6578d90c2339ac05031f42d124fd68147bf455287d656519b7dbd5a2c736531`.
Supervised elapsed7330.5943492seconds (2h02m10.594s), no forced outer
termination, zero owned processes, fixture removed and no cleanup/source errors.
Receipt SHA256 is
`431848642414e38b3ad85b62ec0f3f4eb9c58f15eaed24a04418c4b9e4377091`.

The original guest crash did not reproduce. This direct-host run had no JIT
runner or Actions association and remains `diagnosticOnly=true`,
`qualificationPassed=false`. It does not establish a root fix, replace the real
Actions acceptance, clear the existing comparison quarantine or qualify the
previously failed hosted lane. The quarantine file digest was unchanged across
this attempt. Successful disposal was appropriate because no failed fixture was
produced. No60minute performance result is claimed under NoOverallTimeout.

## Ordered diagnostic passed; hosted diagnostic failed — 18 October 2026 UTC

The [release-order receipt and digest manifest](evidence/ci-poc-003-release-order-775eda14/manifest.json)
preserve lease `775eda141ee1492d890a5309f331a84b` on controller
`b86b3f88dc1cd4ebf8b19934e6daf49e57039a56`, tree
`950b4b8526dee2dca00a5e1202cd0ddc1fd264fc`, and unchanged candidate
`2268468cb3040b9e1dd6deed60d0f13594f768d6`.
Six authenticated six-CPU READY/stop pairs covered source creation/restart,
fresh clone, source reset, saved stateful clone and imported instance. The
workload asserted persistence in stateful/imported guests and its absence in
fresh/reset guests. Child exit0, elapsed2111.7476304seconds (35m11.748s), no
forced outer termination, owned processes0, fixture removed, unchanged sources
and no cleanup errors. This remains diagnostic-only, not the complete release
scenario or proof the original crash is fixed. Neither focused diagnostic
reproduced that crash; the failed production comparison remains quarantined.

[Hosted diagnostic run39171273724](https://github.com/techrote/ezvm/actions/runs/39171273724)
failed with exit1 after4555.4656027seconds (75m55.466s), during base preparation,
before any authenticated READY. Its [unaltered receipt and telemetry](evidence/ci-poc-003-hosted-e0662220-failed/manifest.json)
bind workflow087dc38bdd44f187e29290f5ad4daef4fdcf62f0, controller11fa575 and
the same candidate2268468. Source unchanged, outer child exited, owned
processes0 and fixture removed. The final image-info operation ended at
2136.2433844seconds and base build failed at4539.6492937seconds, a2403.4059093
second gap consistent with the2400second guest deadline and termination
overhead. The actual underlying guest failure is not established. Outer
`cleanup.forced=false` does not prove the candidate never force-stopped QEMU.

The candidate already emits bounded base-stage `failure.json` and `serial.log`
tails with `BASE_LOG_LINE=` framing. Controller11fa575's reducer ignored that
framing, so its empty public signals do not prove the raw record lacked useful
diagnostics. The narrow follow-up recognizes those frames only in exact
`.build-<UUID>` sections, emits closed failure codes/numeric deadline facts and
capture coverage, and never feeds stripped guest content to the host marker
oracle. Original receipts are not rewritten and all functional assertions,
source/cleanup gates and per-operation limits remain required.

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
The subsequent release-order diagnostic and hosted result are recorded above.

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
