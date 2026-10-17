# EzVM observations informing Runloc

These are dated research observations, not a Runloc runtime acceptance report.
No owner VM, credential, private patch or TRIO worker is part of this repository.

## Observed evidence

- [Hosted release job](https://github.com/techrote/ezvm/actions/runs/39022570303/job/117367136257),
  17 October 2026, Windows 2022/TCG candidate24ca91a: cancelled near its180-minute
  timeout. Available log analysis identified about39.45 minutes in tiny image
  checks,13.2 minutes base build,66.16 minutes across 8 READY waits,23.58 minutes
  clone/export/import and 9 minutes cold relocation. This was neither a complete
  PASS nor a Linux runner baseline; wall intervals include validation overhead.
- [EzVM pilot draft PR46](https://github.com/techrote/ezvm/pull/46): clean
  candidate0ab4736 bootstrap passed. Controller stopped the owned attempt after
  422.83seconds before guest execution once a private-key ACL prerequisite failure
  was independently reproduced. Corrected26c6196 preflight blocked in 0.62seconds,
  exit 2, without starting qualification. No WHPX speed qualification resulted.
- The local full PowerShell 5.1 suite was356 PASS / 2 FAIL; both failures were the
  clean upstream private-key ACL path requiring SeSecurityPrivilege. Testing the
  generic ACL helper alone missed this path. Owner patches were excluded.
- Pending [EzVM PR45](https://github.com/techrote/ezvm/pull/45) concerns captured-start
  process ownership and lifecycle deadlines. It was not imported into that pilot;
  its existence is context, not proof of a Runloc fix.
- Hosted-first independent workflow dispatch avoids a private runner queue holding
  hosted execution. It does not shorten a still-required hosted merge check.

## Actions in this programme

| Lesson | Action and verification |
|---|---|
| Generic preflight missed actual failing permission path |002 exact synthetic ACL probes;005/006 real control-file tests |
| Captured pipes can retain process ownership |004 owned process/QMP and descendant-pipe tests;011 controller-death qualification |
| Validation/image work can dominate boot |005/003 scoped integrity checks;009 phase metrics;012 measured split |
| Idle/online markers and prose are weak evidence |007 API job identity;008 host disposal;011 negative controls |
| Immutable source and credential boundaries matter |005 sanitized bases;007 host-only auth;008 never reuse used overlays |
| Concurrent lanes race/offline queues outlive execution timeouts |010 exact private-attempt TTL, lost-response reconciliation and hosted independence |
| A Linux VM is not a Windows runner | Scope00 and016 explicit Windows feasibility; never compare incompatible jobs |
| Long broad tasks hide unfinished gates | Small dependency issues with executable oracles and014 whole-release audit |

Carry new experiments into append-only dated notes with exact source, test scope,
host/guest/profile, positive/negative controls, outcome and uncertainty. Turn an
accepted finding into a linked regression issue or RAG change. Do not rank systems
from configured limits, tiny smokes or incomplete runs. EzVM may later consume the
public evidence schema; changing its repository is a separate task.
