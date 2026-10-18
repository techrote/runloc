# CI-POC-002 implementation checkpoint

Status: full physical Actions qualification and runner lifecycle acceptance passed
with retained evidence on 18 October 2026. Final review and normal merge are the
remaining closeout gates. CI-POC-001 is already qualified and merged
at Runloc `6c38e30af38993cc193d4c46ec5db55910a2b353`. Its original physical
receipt remains unchanged and does not qualify this successor.

The owner explicitly selected eight CPUs and no overall Runloc time limit for
the first issue22 attempts on 18 October 2026, then reduced the next attempt to
six vCPUs after the interrupted run. NoOverallTimeout remains selected. The
immutable EzVM candidate is
`2268468cb3040b9e1dd6deed60d0f13594f768d6`, tree
`d5677a166e54583f26e3f08e90e5836c19f99359`, published on draft
[EzVM PR46](https://github.com/techrote/ezvm/pull/46). It is not EzVM main.
All15 controller manifest pins independently match the public candidate.

## Interrupted full run and successor preparation

[Run39127529716/job117675712339](https://github.com/techrote/ezvm/actions/runs/39127529716)
used runner42 and passed exact preflight, then lost communication. Its
[retained failed record](evidence/ci-poc-002-actions-interrupted.json) has no
final supervisor exit or cleanup receipt; the owned disk/workspace material
remains quarantined. Reconcile confirmed remote absence and retained uncertain
local material instead of fabricating disposal. Last telemetry was
12:47:18Z at992.5246148seconds, before guest startup. GitHub reported lost
communication at12:57:10Z. No host reboot occurred; no runner/QEMU processes
remained at inspection. The user reported closing Codex. The abrupt cutoff
and ten-minute server detection lag are consistent with termination of the
Codex-launched process tree, but do not independently prove that trigger.
This attempt failed; no prior partial PASS marker overrides it.
The [redacted phase record](evidence/ci-poc-002-interrupted-phase-events.json)
retains every observed operation and duration, marks open spans incomplete, and
binds the privately retained original telemetry digest. It is not a closed or
successful telemetry receipt.

The owner requested an app-independent visible terminal and six vCPUs for the
next attempt. The successor controller/oracle requires6 for intent, request and
each authenticated guest CPU observation; all eight READY occurrences and all24
markers remain required. Earlier numeric8 requests/proofs are negative controls.
The generic frozen EzVM resource helper supports6 without a product source
change. At the d3be2aa preparation checkpoint the existing workflow still
selected the earlier controller, so its pin was executionApproved=false until
the six-vCPU controller could be published, reviewed and repinned. An actual
clean-source Start check refused the old workflow with exit1 and
approved-workflow-pin-required, before any registration.

The [real independent-console test](evidence/ci-poc-002-independent-console-test.json)
started no live job/registration. Terminating the launching process's owned
Windows Job left the Explorer-owned console heartbeat advancing; the probe
then exited0 on request. This tests launcher lifetime, not qualification.
The visible read-only monitor likewise starts no runner/guest/job.

The six-vCPU checkpoint d3be2aa's first PowerShell7.6.6 CI job
[117691251496](https://github.com/techrote/runloc/actions/runs/39132807556/job/117691251496)
failed the existing contained-child normal-completion assertion in the entry
exit-semantics group. Its generic failure text does not identify which result
flag failed, so no root cause is claimed. The original failed log is retained.
An unchanged-source rerun
[117691697930](https://github.com/techrote/runloc/actions/runs/39132807556/job/117691697930)
passed59 pilot/21 supervisor/14 runner groups, with0 platform skips. The
PowerShell5.1 lane also passed, as did Windows/Ubuntu repository checks. No
assertion or deadline was changed to obtain this result; the red attempt is
not erased or attributed to the physical interruption.

The next-attempt definition was published through normal expected-head merge
of [EzVM PR52](https://github.com/techrote/ezvm/pull/52), after independent source
review and green core/repository/ordinary-user checks. Hosted full TCG remained
explicitly deferred. Merged commit
a3c6d3ec4c7506d8f8d1c553eb7a4560ddc61d4d has tree
0a2d286f0bb7a97dccb2f07e82005f195c93ce91, identical to its reviewed head.
Immutable tag ci-poc-002-a3c6d3ec4c7506d8f8d1c553eb7a4560ddc61d4d and
workflow LF SHA25672f38d9e740b21743bb73805b043d32c0e292945b26fdea11291c45bd85f8b23
bind frozen six-vCPU job controller d3be2aa7677c338fab86508da6f390fcae1bc541.
The host workflow pin is now execution-approved for that exact definition.
Publication, approval and a live read-only monitor are not a new run. No full
attempt was restarted under the owner's next-time instruction; CI-POC-002
remains open and unqualified pending the next complete physical execution.

## Actual software results

- Clean local Windows PowerShell5.1: **406 passed,0 failed,0 skipped**.
- [EzVM core/repository lanes](https://github.com/techrote/ezvm/actions/runs/39123607809):
  both Windows PowerShell5.1 and pinned PowerShell7.6.6 pass; repository contract passes.
- [Ordinary-user lanes](https://github.com/techrote/ezvm/actions/runs/39123607813):
  both supported engines pass. Exact artifact/source audit will accompany final evidence.
- Hosted full TCG remains explicitly skipped/deferred under issue23. It was not restarted.
- Local Runloc Windows PowerShell5.1: **59 pilot/21 supervisor groups**, no skips.
- New runner controls: **14 groups** pass on local Windows PowerShell5.1 and
  PowerShell7.6.5. That latter local sanity check is not the required pinned7.6.6 CI lane.
- Repository contracts and all21 Python tests pass.

The initial dirty EzVM test run retained403 passes and2 failures: the extracted
guest-start fixture omitted the new defaultCPU variable, and release packaging
correctly refused dirty source. The fixture was corrected, original assertions
were retained, and the committed clean successor passed406/406. A PowerShell7
runner test initially exceeded the native short-path budget because its test
fixture did not model the production shortWorkParent; correcting that fixture
preserved native path guards and all ownership assertions.

The first public Runloc checkpoint's Windows helper lanes passed59/21/13 in
both supported engines. Its repository negative controls caught a copied-test
fixture that omitted new linked PoC files. The fixture now copies those actual
source/doc targets; link and contract assertions remain unchanged.

## Review and remaining gates

The primary model agent authored/integrated the implementation. A separate
Extra High model reviewer independently checked the source, all15 candidate
pins, JIT/credential boundaries, workflow source binding, receipt/CPU oracle,
process ownership and nested external-fixture cleanup. Material findings around
mutable-ref verification, diagnostic-write failure, nested fixture disposal,
dispatch identity and failure-after-success were repaired and re-reviewed.
This is model review, not external human approval.

The manual-only workflow was published by normal expected-head squash merge of
[EzVM PR49](https://github.com/techrote/ezvm/pull/49) at
`62038cf8db68e8b863054c112d79b727e8776031`, tree
`d48b97e2baa848c415a79b7beee85122c4238ec8`. The merged tree equals the
independently reviewed PR head tree. All exact-head automated checks passed;
the hosted full TCG lane remained intentionally skipped. Immutable tag
`ci-poc-002-62038cf8db68e8b863054c112d79b727e8776031` identifies that source.
The workflow LF SHA256 is
`85c64bbe9e19a4ab303f40dcff83cadde06ba5099eab7981115f33402a10e410`.
It checks out job controller `14c39e467f170e48f33af4e50b2c0e8e095b4f6e`.
The host dispatcher separately pins that commit, workflow commit and hash in
`runner-workflow.json`; moving a tag or supplying an equivalent definition from
another commit is refused.

The [first real startup failure](evidence/ci-poc-002-jit-startup-failure.json)
is retained with its exact controller identity and exit1. Registration37 was
created, but no listener or workflow started: the live JIT service supplies the
Ephemeral setting as a string, whereas the initial validator required a JSON
boolean. An independent diagnostic registration38 recorded only schema names,
types and comparison results, never the capability or credential values. Both
registrations were independently confirmed absent. Owned processes were0,
the owned fixture was removed, source and unrelated sentinel were unchanged,
and the pinned backing archive survived. This is failure evidence, not a
successful no-job-timeout or qualification result. The narrow repair accepts
only explicit true boolean/string literals and normalizes them to a boolean;
false, numeric, missing and truthy arbitrary strings remain negative controls.

The [real no-job deadline case](evidence/ci-poc-002-no-job.json) then started
registration39 and observed it online with only its unique label. At the
45-second no-job deadline the owned listener was terminated with exit124;
supervisor exit1 and `passed=false` remained mandatory. Total supervised time
was49.4962335seconds. Independent API confirmation showed registration absent,
active processes0, fixture removed, controller unchanged, and backing archive
and unrelated sentinel preserved. This proves truthful timeout cleanup, not
physical qualification.

Fresh registration40 accepted [actual Actions job117671387479 in
run39126080753](https://github.com/techrote/ezvm/actions/runs/39126080753).
Its [failed evidence](evidence/ci-poc-002-actions-shell-failure.json) records
supervisor exit1 despite listener exit0 and normal cleanup. The generated first
PowerShell script was blocked by host execution policy, before checkout or
preflight; no harness ran. Narrow [EzVM PR50](https://github.com/techrote/ezvm/pull/50)
uses a dedicated process-local Bypass shell with a quoted script path. A local
space-path negative control observed Restricted exit1 without script execution,
Bypass exit7 with exactly one marker, and unchanged host policy. Independent
review verified the pinned runner's script-extension/failure handling and both
retained lifecycle records. A fresh complete attempt is still required.

PR50 passed both core engines, both ordinary-user engines and the repository
contract, with hosted full TCG still explicitly skipped. It merged normally
at `e516c92569247abd5c8282ed5cbda3a00cf241b6`, tree
`14a237f3873484a91e99ebf2c67e37f255a425e5`, identical to its reviewed PR tree.
The successor immutable tag is `ci-poc-002-e516c92569247abd5c8282ed5cbda3a00cf241b6`;
its workflow LF SHA256 is
`dab5a3bc97b439ecdc6b98f11eedda4e7083d1616c27ea9a20882a1122c864dc`.
The frozen job controller and eight-CPU candidate are unchanged.

The next fresh registration41 executed [run39126788794/job117673494204](https://github.com/techrote/ezvm/actions/runs/39126788794).
Validation and checkout passed, but exact source verification stopped before
preflight with `source-public-blob-mismatch`. The [original failed receipt](evidence/ci-poc-002-actions-checkout-failure.json)
retains host exit1, listener normal exit0, process0, exact registration absent,
fixture removed and preserved backing/source/sentinel; no physical result is
claimed. [Focused clone controls](evidence/ci-poc-002-checkout-probe.json)
identify extensionless LICENSE conversion under native Windows text=auto.
Both `core.autocrlf=false` and `core.eol=lf` are required for the reviewed bytes;
autocrlf=false alone still allowed native CRLF. Narrow
[EzVM PR51](https://github.com/techrote/ezvm/pull/51) supplies both settings only
to checkout's process environment. The [exact environment-method probe](evidence/ci-poc-002-checkout-env-probe.json)
passes complete165-file source verification after restoring that environment,
with an unchanged local Git config digest. Blob checks, source, candidate,
host Git settings and original qualification assertions remain unchanged.

PR51 passed both core and ordinary-user engine lanes plus the repository check,
with full hosted TCG still skipped by the owner deferral. It merged normally at
`e1b36aac861000503764bee53d7cd1a09b984103`, tree
`6d890c552219512abfb316c85e6a0bcbac27b5c4`, matching its reviewed PR head.
The successor tag is `ci-poc-002-e1b36aac861000503764bee53d7cd1a09b984103`;
the pinned workflow LF SHA256 is
`9d13479ea3fa286b4ba6e770f952cda19d1c71306144bd9f42124484f5598fb3`.

Completion still requires a real full eight-CPU WHPX Actions job and exact
run/job/runner/receipt evidence, actual process exit and deregistration404,
owned workspace and external fixture cleanup, a used-registration second-job
refusal, a different fresh-registration reuse probe on the preserved backing
environment, and a real failed/no-job cleanup case. These are acceptance gates,
not inferred from an online runner or the ephemeral/once flags.

### Six-vCPU attempt: disk preflight failure (2026-10-18)

[Actions run 39141501369](https://github.com/techrote/ezvm/actions/runs/39141501369)
accepted the fresh native Windows runner registration 43, but did not reach the
full release harness or boot a guest. The ACL preflight passed; available disk
space was 56.3 GiB against the unchanged 60 GiB requirement. The
[redacted failure record](evidence/ci-poc-002-disk-preflight-failure.json)
retains exact source identities, receipt digests, observed numeric inner,
supervisor and listener exits, and confirmed cleanup. The host controller's
numeric exit was not captured by the console and remains unknown for this
attempt. This is a failed attempt, with zero guest READY responses and no
physical qualification result. Original private receipts remain retained.

The console now retains its controller process handle before exit and explicitly
reports whether the numeric exit was observed. A real child exiting 7, observed
after termination, covers this correction in both PowerShell engines. The owner
freed disk space; the subsequent read-only check found 80.49 GiB free. A fresh
attempt is required. The workload remains the complete six-vCPU qualification;
no disk guard, completion assertion or receipt oracle was relaxed.

## Successful full qualification and lifecycle closeout — 18 October 2026

The earlier pending-gate lists above describe historical checkpoints. The
following retained evidence supersedes those lists without overwriting red runs.

[Full run39142236233/job117718844700](https://github.com/techrote/ezvm/actions/runs/39142236233/job/117718844700)
completed successfully using runner44, independent attempt/lease
`62161502eccf49efb3f7fc90890ac639`. The
[original allowlisted artifact](evidence/ci-poc-002-full/actions-job.json),
[host lifecycle receipt](evidence/ci-poc-002-full-host.json) and
[byte manifest](evidence/ci-poc-002-full-manifest.json) retain the complete proof.
All published receipt/digest/telemetry files preserve their observed bytes;
`.gitattributes` disables newline conversion for these two evidence directories.
Raw runner/guest logs, credentials, private keys and machine secrets are excluded.
The private originals remain available locally. The public artifact is125848bytes,
GitHub artifact12144329970, archive SHA256
`1ce794226b297113cf6cc5186ea3d79f2849b3498e790e3302d66b62574cb698`.

Exact executed identities:

| Component | Commit | Tree |
|---|---|---|
| Host controller | `e66b32c66b3926427f379f716d0a352f63fa8500` | `7e105d4a5e47e8c39f08756fc32c474c415454bd` |
| Frozen job controller | `d3be2aa7677c338fab86508da6f390fcae1bc541` | `e98d68fce03bc39fcb779efc5bd26e60d600b57c` |
| EzVM candidate, draft PR46 | `2268468cb3040b9e1dd6deed60d0f13594f768d6` | `d5677a166e54583f26e3f08e90e5836c19f99359` |
| Trusted workflow, merged PR52 | `a3c6d3ec4c7506d8f8d1c553eb7a4560ddc61d4d` | `0a2d286f0bb7a97dccb2f07e82005f195c93ce91` |

The workflow's LF SHA256 is
`72f38d9e740b21743bb73805b043d32c0e292945b26fdea11291c45bd85f8b23`.
The native official runner is2.337.0, archive SHA256
`1150692afa94e71f872017e254ea55b6eece1eece3fe7e3a6d4c93d0a1b85cfc`.
Host label `lab-win11-01` identifies Windows11Pro26300, Ryzen5600X,
12logical processors, ordinary-user execution with no SeSecurityPrivilege.
The guest resource request is six vCPUs per guest; original concurrent-guest and
memory assertions remain. Full tool, image, base, guest and source identities
are in the inner receipt; QEMU version is11.1.2.

The complete original scenario passed all24 markers, all8authenticated READY
responses, and all8six-vCPU proofs. Requested accelerator, prepared base and
all guest identities agree on WHPX. Actual harness and inner controller exits
are0, both outer supervisor exits are0, listener exit is0, and the Explorer
console observed the actual host-controller exit0. Immutable source remained
unchanged. Host cleanup confirmed zero owned processes, disposal of both nested
qualification fixtures and the runner workspace, exact deregistration, preserved
backing archive/environment and unrelated sentinel. No forced cleanup, timeout,
cancellation or missing assertion qualified this run.

Timing scopes are distinct: inner qualification7452.3461127seconds; outer full
supervisor7460.6199699seconds; complete Actions helper including separate
preflight7471.910846seconds; whole host registration/job/cleanup7522.7706465seconds
(**2h5m22.771s**), finishing17:54:56Z /18:54:56UK. The owner explicitly selected
NoOverallTimeout, so the former60/90minute overall gates were disabled for this
matching receipt policy. Original per-operation limits remain. This establishes
correctness and lifecycle acceptance, not a CI speed improvement.

All2514telemetry records and phase durations are retained in the full artifact.
There were292complete payload-integrity checks,6671.4507383inclusive seconds.
These overlapping operation durations must not be summed as wall time. Recorded
operation exceptions include deliberately asserted negative controls; final
exit/marker/source/cleanup oracles passed. No validation was removed to improve
performance.

### Independent registration lifecycle proofs

[Lifecycle evidence](evidence/ci-poc-002-lifecycle.json) records three exact
registrations and direct404observations:

- After full registration44 exited and disappeared, an approved probe workflow
  targeting its old UUID label was dispatched as
  [run39152771978/job117749632366](https://github.com/techrote/ezvm/actions/runs/39152771978).
  It remained unassigned (`runner_id=0`, no steps) and was cancelled by exact runID.
  No replacement runner was registered under that label. This independently
  exercises the used-registration second-job prohibition; the cancellation is
  the expected negative-test outcome and is not a qualification PASS.
- The same preserved backing environment then created fresh registration45,
  lease `73f4c1ce39fa43e9ab55472ba175971c`, with a distinct mutable workspace.
  [Run39152894611/job117749999473](https://github.com/techrote/ezvm/actions/runs/39152894611/job/117749999473)
  accepted and passed the authorized bounded preflight-only reuse probe.
  [Original reuse receipts](evidence/ci-poc-002-reuse/actions-job.json) explicitly
  report `physicalQualificationPassed=false`; a second full run was unnecessary.
  Actual controller exit0, listener exit0, host elapsed60.1220586seconds;
  registration absent, owned processes0, fixture disposed, source/backing/sentinel
  preserved.
- Fresh registration46, lease `3ae304f735c240eb8fe48b6273e2c501`, exercised a
 30second no-job deadline on the same host controller/workflow. It truthfully
  failed `no-job-deadline`: controller exit1, listener terminated124,
  host elapsed36.4147128seconds. Owned processes reached0; exact registration
  disappeared and fixture was removed; backing/source/sentinel survived.
  This supplements the earlier retained runner39 no-job failure, not a green run.

The final observer reads the digest-checked retained non-preflight receipt after
workspace disposal and prints24/24,8/8,8/8 with actual exit and supervised time.
It distinguishes retained results from live process state and rejects modified
receipt bytes. Missing retained details remain explicitly unavailable. An earlier
monitor-only PS5.1 Int32-overload failure is fixed with explicit floating-point
Math.Max arguments and a4GiBread/3GiBwrite regression. These observational changes
and the hidden synthetic test child do not change any executed qualification,
job-controller, candidate, runner registration, receipt oracle or cleanup code.
The original executed checkpoints above remain the physical evidence identity;
the final PR is not falsely labelled as the historical executed whole tree.

The independent model reviewed the complete diff, source pins, credential and
process boundaries, receipt oracle, cleanup, and real API/physical evidence.
Its finding about assuming inactivity from any final event was corrected with
neutral retained-result wording. The primary model authored/integrated the
changes; independent model review is not claimed as external human approval.
Final exact-head checks and review disposition are recorded on PR26.

CI-POC-003/#23 retains CI gating/fallback and restoration or replacement of the
owner-deferred hosted TCG policy. This run makes no TCG coverage, speed-resolution,
RAM-disk performance, host-account isolation, service or fleet claim. Earlier
interrupted runner42 material remains explicitly quarantined; it was not reused
or reclassified as clean success. CI-POC-001/#21 stays completed and closed.
