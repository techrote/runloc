"""Render the issue mirrors and programme from the canonical catalogue (no network)."""
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = 'https://github.com/techrote/runloc'
COMMON = ['AGENTS.md', 'README.md', 'docs/programme/IMPLEMENTATION-PROGRAMME.md',
          'docs/programme/PLAN-REVIEW.md', 'docs/rag/README.md', 'docs/rag/00-SCOPE.md',
          'docs/rag/08-TESTING-ACCEPTANCE.md', 'docs/rag/11-SOURCES.md']

def load(root: Path = ROOT) -> dict:
    return json.loads((root / 'docs/programme/issues.json').read_text(encoding='utf-8'))

def url(path: str) -> str:
    return f'{BASE}/blob/main/{path}'

def issue_url(item: dict) -> str:
    if item.get('issue_number'):
        return f'{BASE}/issues/{item["issue_number"]}'
    return url(f'docs/programme/issues/{item["id"]}.md')

def bullets(values: list[str]) -> str:
    return '\n'.join('- ' + v for v in values)

def render_issue(item: dict, catalogue: dict) -> str:
    lookup = {i['id']: i for i in catalogue['issues']}
    deps = ', '.join(f'[{d}]({issue_url(lookup[d])})' for d in item['depends_on']) or 'None; start here.'
    reading = list(dict.fromkeys(COMMON + item['rag'] + ['docs/research/EZVM-FIELD-NOTES.md']))
    docs = '\n'.join(f'- [{p}]({url(p)})' for p in reading)
    return f'''# {item['id']} — {item['title']}

Stage: **{item['stage']}**. Planning status: **{item['status']}**. This issue is not implemented by publication of the programme.

## Dependencies and prerequisites

Depends on: {deps}

{item['prerequisites']}

Confirm dependency PRs are accepted on current main before coding. Follow-on issues do not block v0.1.

## Autonomous execution prompt

Implement **{item['id']}** end to end in `techrote/runloc`. Fetch current main; read this complete live issue and every comment, dependency result, overlapping PR and the linked instructions below. Use an isolated `runloc-{item['id'][-3:]}-short-name` branch. The owner authorizes the ordinary implementation, tests, PR and merge cycle under these contracts; routine confirmation is unnecessary. Do not start a later issue or deploy unrelated infrastructure.

The scope, observable acceptance and tests below are binding. Inspect existing code first and preserve already accepted work. Add meaningful retained regressions and exact-source checks; use synthetic credentials and temporary assets. Update affected RAG contracts with implementation. Review and improve the change before opening the PR; record the actual reviewer/author roles without claiming independence from self-review.

## Required instructions and RAG material

{docs}

## Scope to deliver

{bullets(item['scope'])}

## Observable acceptance criteria

{bullets(item['acceptance'])}

## Required implementation/testing work

{bullets(item['tests'])}

Also run `python scripts/check_repository.py` and `python -m unittest discover -s tests -p "test_*.py"`. From RUNLOC-001 onward run the consolidated `python scripts/check.py` and the issue's focused tests. All commands must target the intended checkout. Normal PR checks must require no VM/API credentials; separate physical/live acceptance is required only where specified and cannot be replaced by a mocked or all-skipped pass.

## Excluded scope

{item['excludes']}

## PR, automated checks and autonomous merge

Commit only clean intended source/tests/docs. Push a PR containing `Closes #<this issue number>`, a concise behavior summary, actual test/evidence links, limitations and RAG updates. Do not close this issue through a partial implementation. Inspect final diff and resolve material review findings. Wait for **all actual required automated checks on the exact PR head**, with about 120-second polling intervals. Fix relevant failures; do not disable checks or merge known-red work.

When dependencies and every acceptance clause are satisfied, required checks are green, review threads are resolved and no owner hold exists, squash-merge using the exact expected head. Do not use admin overrides or weaken branch protection. Verify the resulting main and post-merge checks, then add a factual completion comment with source/evidence and update programme status. If post-merge acceptance fails, reopen the issue and repair it.

If permissions, required review, approved hardware, credentials or another binding prerequisite is unavailable, preserve a reviewable draft PR and exact blocker. Never enroll credentials, change host privileges, fake physical acceptance or declare a merge that did not happen. A documented no-go completes a research issue only when its acceptance criteria explicitly allow it.

Canonical scope: [issues.json]({url('docs/programme/issues.json')}); repository mirror: [{item['id']}.md]({url(f'docs/programme/issues/{item["id"]}.md')}).
'''

def render_index(catalogue: dict) -> str:
    rows = []
    for item in catalogue['issues']:
        deps = ', '.join(item['depends_on']) or '—'
        rows.append(f'| [{item["id"]}]({issue_url(item)}) | {item["title"]} | {deps} | {item["stage"]} | {item["status"]} |')
    return '''# Runloc implementation programme

Reviewed 17 October 2026. **Planning complete; runtime implementation not started.**
The owner selected Linux runners first on Windows/WHPX, Windows guests later.
Runloc's own source/docs use MIT. Read [AGENTS](../../AGENTS.md),
[scope](../rag/00-SCOPE.md), [RAG index](../rag/README.md) and
[review/revisions](PLAN-REVIEW.md) before beginning an issue.

## Delivery boundary

V0.1 is RUNLOC-001 through RUNLOC-014: a small Python CLI, clean image/toolchain, safe
one-job VM lifecycle, API-bound GitHub execution, bounded evidence/stats,
independent hosted/private comparisons, failure recovery, real WHPX timing and
a reproducible release. RUNLOC-015–019 are separately gated follow-ons. Do not implement
every future feature before shipping the accepted one-job product.

```mermaid
flowchart LR
  A[CLI and verified tools] --> B[Storage and owned QEMU]
  B --> C[Prepared Linux image and guest control]
  C --> D[JIT runner and one-job disposal]
  D --> E[Metrics and paired dispatch]
  E --> F[Recovery qualification and timed WHPX pilot]
  F --> G[Packaging and v0.1 release]
  G --> H[Optional queue, Windows, KVM, autoscaling and gate promotion]
```

## Issues and dependencies

Numbers follow a valid topological order. Independent branches can progress once
their own dependencies are accepted; numbering is not a requirement to serialize
unrelated work. Each live issue contains its complete autonomous execution prompt,
links to instructions/RAG, scoped deliverables, observable acceptance, tests,
exclusions, prerequisites and PR/merge/post-merge gates.

| Issue | Deliverable | Depends on | Stage | Status |
|---|---|---|---|---|
''' + '\n'.join(rows) + '''

## Tracking and execution

[issues.json](issues.json) is the canonical machine-readable catalogue. The
[issue mirrors](issues/) are deterministic reviewable copies of the published
bodies. `python scripts/render_programme.py` regenerates them after an intentional
catalogue update. `python scripts/check_repository.py` checks graph/doc/prompt
consistency without API access. Live issue comments can clarify scope; reconcile
material changes back into these contracts in the implementation PR.

No runloc runtime command, physical acceleration, benchmark, registration or
release is qualified by this planning repository. Required real evidence remains
owned by the relevant implementation issues. Hardware/API-gated issues stay open
when their evidence is missing. Never substitute an available Linux result for a
Windows-only job or a configured accelerator for real WHPX execution.

The [EzVM field notes](../research/EZVM-FIELD-NOTES.md) preserve observed context
and uncertainty. External APIs, runner versions and licences must be rechecked
against [primary sources](../rag/11-SOURCES.md) during implementation. No owner
VMs, EzVM patches or TRIO worker state are part of Runloc's execution scope.
'''

def render(root: Path = ROOT) -> None:
    catalogue = load(root)
    directory = root / 'docs/programme/issues'
    directory.mkdir(parents=True, exist_ok=True)
    for item in catalogue['issues']:
        (directory / (item['id'] + '.md')).write_text(render_issue(item, catalogue), encoding='utf-8')
    (root / 'docs/programme/IMPLEMENTATION-PROGRAMME.md').write_text(render_index(catalogue), encoding='utf-8')

if __name__ == '__main__':
    render()
    print('Rendered programme and 19 issue mirrors; no GitHub writes.')
