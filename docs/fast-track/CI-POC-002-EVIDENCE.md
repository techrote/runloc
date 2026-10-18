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

The approved workflow hash/tag pin must be finalized after normal publication
of its manual-only definition on EzVM main. Start refuses missing pins before
registration. No runner registration or workflow dispatch has occurred yet.

Completion still requires a real full eight-CPU WHPX Actions job and exact
run/job/runner/receipt evidence, actual process exit and deregistration404,
owned workspace and external fixture cleanup, a used-registration second-job
refusal, a different fresh-registration reuse probe on the preserved backing
environment, and a real failed/no-job cleanup case. These are acceptance gates,
not inferred from an online runner or the ephemeral/once flags.
