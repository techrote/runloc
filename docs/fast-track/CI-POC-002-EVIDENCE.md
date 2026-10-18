# CI-POC-002 implementation checkpoint

Status: implementation and software review; real Actions qualification and
lifecycle acceptance remain pending. CI-POC-001 is already qualified and merged
at Runloc `6c38e30af38993cc193d4c46ec5db55910a2b353`. Its original physical
receipt remains unchanged and does not qualify this successor.

The owner explicitly selected eight CPUs and no overall Runloc time limit for
issue22 on 18 October 2026. The successor EzVM candidate is
`2268468cb3040b9e1dd6deed60d0f13594f768d6`, tree
`d5677a166e54583f26e3f08e90e5836c19f99359`, published on draft
[EzVM PR46](https://github.com/techrote/ezvm/pull/46). It is not EzVM main.
All15 controller manifest pins independently match the public candidate.

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

Completion still requires a real full eight-CPU WHPX Actions job and exact
run/job/runner/receipt evidence, actual process exit and deregistration404,
owned workspace and external fixture cleanup, a used-registration second-job
refusal, a different fresh-registration reuse probe on the preserved backing
environment, and a real failed/no-job cleanup case. These are acceptance gates,
not inferred from an online runner or the ephemeral/once flags.
