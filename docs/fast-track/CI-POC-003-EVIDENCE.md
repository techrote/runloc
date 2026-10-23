# CI-POC-003 implementation checkpoint

## Hosted timer comparison reproduces panic in both modes — 21 October 2026 UTC

[Diagnostic run39684084537/job119513601106](https://github.com/techrote/ezvm/actions/runs/39684084537/job/119513601106)
completed its bounded observation in181.5026119seconds. The
[original public summary/digest and API/crypto association](evidence/ci-poc-003-hosted-timer-5c4e91c6/manifest.json)
retain three default and three HPET-off boots. All six reproduced the same early
IO-APIC timer panic on kernel6.8.0-142, before init or six-CPU activation.
Six guest CPUs were requested in every case; no successful guest-CPU proof is
claimed. Both controls retained APIC and kernel checks, the same virtio NIC and
restricted user networking with no forwarding.

Workflowb70fc49, controller3db4aa2 and unchanged candidate2268468 were used on
Windows2022/build20348, image20261012.333.1, four-logical-processor AMD EPYC host.
All original serial bytes and receipt bytes authenticated through the encrypted
artifact, independently repeated by a second model. Sources remained unchanged;
preflight and outer diagnostic child exited0 with no timeout/cancellation/output
failure, owned processes0. The diagnostic fixture was quarantined after panic.
An Actions success here means the observations completed, never qualification:
the original receipt and public summary explicitly deny qualification.

HPET-off has no supporting correction evidence. Local earlier no-NIC controls
on controller6a8dfda reached init in all six cases; that nonreproduction cannot
identify a host or NIC cause. A subsequent local same-NIC run on controller3db4aa2
completed in183.9611007seconds: all six boots reached init and six-CPU activation,
source unchanged, owned processes0 and fixture removed. Its pinned QEMU and image
SHA256 match the hosted probe. NIC presence is insufficient to reproduce this
symptom locally; no single host/environment cause is established. Further focused
scheduling/clock controls retain six guest CPUs and Linux checks. No production change, full release pass, gate
acceptance, quarantine reset or issue completion follows from this diagnostic.

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


## Fresh hosted VM scheduling comparison and mitigation under test

The [four-job diagnostic run39828718868](https://github.com/techrote/ezvm/actions/runs/39828718868)
completed all observations. Original public summaries/digests and exact associations
are retained in [the evidence manifest](evidence/ci-poc-003-hosted-cold-fac68bdf/manifest.json).
Fresh API reads and authenticated private bundle decryption were repeated independently;
all twelve serial/receipt/source/profile associations matched. All four first guest
boots reached init with six CPUs. Multi-thread TCG had one exact IO-APIC timer panic
on replica2 boot2 among six boots; single-thread had none among six boots. These
are correlated observations across two fresh hosted VMs per mode, not twelve
independent physical hosts. CPU models varied; identical image/tool/firmware hashes
were retained. Diagnostic job success reports completed observation, not guest or
release success. Planned guest termination exit124 is retained; outer/preflight
exit0, owned0, and no forced/timeout/cancellation/output failure were recorded.
The panic fixture was quarantined during its job; the other three were removed.
Hosted VM teardown does not imply permanent retention of its disk fixture.

[EzVM PR60](https://github.com/techrote/ezvm/pull/60) tests the narrow empirical
mitigation `tcg,thread=single` in both prepared-base and runtime argument builders,
with six requested guest CPUs and original WHPX/APIC/READY/persistence checks.
No icount or timer-check bypass is added. New candidate
`e29c0a9c9196d55914a4659cf51d7a49c0a21e84`, tree
`3deca45ef74ae7b8a6470cd69dfa8d38cf90674f`, is selected only for fresh qualification;
its two changed argument builders are explicitly pinned alongside the original
harness/image/tool pins. This is not a root-cause or reliability guarantee. Earlier
physical receipts cannot qualify the changed tree. New full six-core hosted TCG
and physical WHPX evidence is required before acceptance. The original quarantine
remains in force; historical source-bound gate allowlists have not been reset or
silently expanded. No gate acceptance, merge or issue completion is claimed.


## Exact e29 mitigation full results and next diagnostic checkpoint

Independent review verified the native physical e29/813 full WHPX pass:
24/24 completion markers, eight authenticated READY/eight six-CPU proofs,
2556 complete telemetry records, supervisor/harness exits0, unchanged clean
sources, owned0, fixture removed and unforced cleanup. Supervisor elapsed was
7189.5074562seconds; its final post-I/O elapsed and actual invocation result are
retained in the [redacted native evidence manifest](evidence/ci-poc-003-physical-e29c0a9/manifest.json).
This was native physical requalification, not a new Actions/gate acceptance;
NoOverallTimeout was owner-authorized, so no60-minute performance claim is made.

The independent [hosted full attempt39840798569](https://github.com/techrote/ezvm/actions/runs/39840798569)
failed with harness exit1 after3801.187794seconds. Its original public receipt,
telemetry and exact API/artifact/source association are retained in the
[failed hosted manifest](evidence/ci-poc-003-hosted-f9597c7b-failed/manifest.json).
Fresh independent download/authenticated decryption matched the original private
log digest. The secondary guest finalizer reported Python venv/pip unavailable
or its90-second validation deadline exceeded; SSH surfaced70. The inner status
and substage were discarded by that source, so timeout versus Python/ensurepip
failure remains unresolved. No matching kernel-panic marker was observed in the
retained log; this does not establish a root fix. Source unchanged, preflight0,
owned0, fixture removed and unforced cleanup were retained despite failure.

EzVM PR60 diagnostic checkpoint `2a624a1d0d90e076cac5b81aebe115d66fa66e65`,
tree `835c1b19917e0185e3c55e0c563f009ee4e126cd`, adds only allowlisted venv
stage/original numeric exit/guest elapsed diagnostics, retaining every command
and the90-second validation bound. The coder-owned stage file read is separately
bounded to16bytes/two diagnostic seconds. Actual-shell controls cover each stage,
124, setup, malformed/large/FIFO data and unavailable/regressing clocks. No unrelated
PR55 panic/runtime changes were imported. This is observability, not a venv repair;
new-source qualification remains pending. The hosted adapter can remain pinned
at813 while an owner-reviewed immutable definition selects this exact new source;
its old physical approval/runner/gate allowlists are not expanded by that selection.
No old physical result transfers to this diagnostic tree, and no quarantine reset,
new gate acceptance, merge or issue completion is claimed.
