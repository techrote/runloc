# CI-POC-002 implementation checkpoint

Status: implementation and software review; real Actions qualification and
lifecycle acceptance remain pending. CI-POC-001 is already qualified and merged
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
