"""Render and validate the bounded CI PoC; contains no runtime/registration code."""
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = 'https://github.com/techrote/runloc'
IDS = [f'CI-POC-{n:03}' for n in range(1,4)]
READING = ['AGENTS.md','docs/fast-track/README.md',
           'docs/fast-track/WINDOWS-WHPX-CI-POC.md',
           'docs/rag/07-SECURITY-RECOVERY.md','docs/rag/08-TESTING-ACCEPTANCE.md',
           'docs/research/EZVM-FIELD-NOTES.md']

def load(root: Path = ROOT) -> dict:
    return json.loads((root/'docs/fast-track/issues.json').read_text(encoding='utf-8'))

def link(item: dict) -> str:
    return f'{BASE}/issues/{item["issue_number"]}' if item.get('issue_number') else f'{BASE}/blob/main/docs/fast-track/{item["id"]}.md'

def render_issue(item: dict, data: dict) -> str:
    lookup = {i['id']:i for i in data['issues']}
    dependencies = ', '.join(f'[{d}]({link(lookup[d])})' for d in item['depends_on']) or 'None. Start here; the19-issue product programme is not a prerequisite.'
    reading = '\n'.join(f'- [{p}]({BASE}/blob/main/{p})' for p in READING)
    sections = []
    for field, title in [('scope','Implementation scope'),('acceptance','Observable acceptance'),('tests','Required tests and evidence')]:
        sections.append('## '+title+'\n\n'+'\n'.join('- '+v for v in item[field]))
    return f'''# {item['id']} — {item['title']}

**Urgent Windows CI proof of concept. Status: {item['status']}.** Creating this issue is not implementation or qualification.

## Dependencies and autonomous prompt

Depends on: {dependencies}

Implement this issue autonomously in the short Windows/WHPX chain. Fetch current Runloc/EzVM main, read this entire live issue/comments, accepted dependencies, linked instructions and overlapping EzVM PRs43/45/46. Use a clean isolated `ci-poc-{item['id'][-3:]}-short-name` branch. The owner authorizes the ordinary implementation/test/PR/merge cycle; no routine confirmation is needed. A real external permission or hardware blocker must remain explicit.

Do not wait for or implement RUNLOC-001–019. This is an interim native Windows host runner for the existing Windows test; it is not the Linux disposable-VM product. Follow the dedicated contract's platform/path/frozen-candidate exceptions, while keeping all credential, ownership, source/evidence and no-bypass safeguards.

## Required instruction and RAG links

{reading}
- [EzVM current agent instructions](https://github.com/techrote/ezvm/blob/main/AGENTS.md)
- [EzVM testing/CI contract](https://github.com/techrote/ezvm/blob/main/docs/rag/08-TESTING-CI-RELEASE.md)
- [Existing pilot PR46](https://github.com/techrote/ezvm/pull/46)
- [Pinned pilot implementation/evidence contract](https://github.com/techrote/ezvm/blob/26c61967e91a008082ebc197f16dd94b943ad27c/docs/CI-QUALIFICATION-COMPARISON.md)

{chr(10).join(chr(10)+s+chr(10) for s in sections)}
## Excluded scope

{item['excludes']}

## PR and completion gate

Put minimal helper/tests/docs in Runloc `poc/windows-whpx/`; put EzVM product/workflow fixes in its clean upstream PRs without copying private patches or relicensing source. Link exact upstream candidate SHA and real PR disposition. The accepted frozen-candidate lab dependency is described in the dedicated contract: do not merge red upstream work just to advance this chain.

Run `python scripts/check_repository.py`, `python -m unittest discover -s tests -p "test_*.py"`, focused PoC tests and applicable EzVM tests. The not-yet-implemented full Runloc CLI/harness is not a prerequisite. Normal PR checks never require live credentials or hardware. Physical/API acceptance above must actually happen; no all-skipped or mocked substitute.

Review final diff and real results, retain original red/green evidence, correct material findings and record actual author/reviewer roles. Push a Runloc PR with `Closes #<this tracker>`, source/evidence links, RAG updates and limitations. Merge only after this issue's acceptance, required exact-head automated checks and resolved reviews, using the expected head and no admin override. Monitor checks around120seconds, not tight polling. Verify main/post-merge checks and comment with factual completion evidence; reopen if acceptance fails. Binding missing prerequisites leave a draft and open issue.

The owner asked for this bounded PoC now; this issue does not authorize changes to owner VMs, privileges, GPUs/models, unrelated code or production branch policy beyond its reviewed stated scope. No private runner or pilot is started by publishing this plan.
'''

def render_index(data: dict) -> str:
    rows = '\n'.join(f'| [{i["id"]}]({link(i)}) | {i["title"]} | {", ".join(i["depends_on"]) or "None"} |' for i in data['issues'])
    return '''# Immediate EzVM CI fast track

**Three issues; no dependency on the19-issue Runloc product.** Planning only.
The owner requested a small proof of concept to resolve the existing Windows CI
bottleneck now, using the already prepared local WHPX test setup.

Read the [PoC contract](WINDOWS-WHPX-CI-POC.md) and [AGENTS](../../AGENTS.md).

| Issue | Deliverable | Depends on |
|---|---|---|
'''+rows+'''

The bridge uses an on-demand one-job **native Windows runner**. Its qualification
QEMU guests are disposable, but the host is not a disposable VM. The main
[Linux-first programme](../programme/IMPLEMENTATION-PROGRAMME.md) remains separate.
The third issue must remove the effective CI wait through an explicit reviewed
gate/fallback policy; adding optional comparisons alone does not complete the PoC.

[Catalogue](issues.json) and adjacent issue mirrors are checked locally and in CI.
No issues are closed and no runner is registered by publishing this chain.
'''

def render(root: Path = ROOT) -> None:
    data = load(root)
    for item in data['issues']:
        (root/f'docs/fast-track/{item["id"]}.md').write_text(render_issue(item,data),encoding='utf-8')
    (root/'docs/fast-track/README.md').write_text(render_index(data),encoding='utf-8')

def validate(root: Path, *, require_published: bool = True) -> list[str]:
    directory = root/'docs/fast-track'
    if not directory.exists():
        return []
    try:
        data = load(root)
    except (OSError,ValueError) as exc:
        return [str(exc)]
    errors = []
    if data.get('schema_version') != 1 or data.get('repository') != 'techrote/runloc' or data.get('maximum_issues') != 3 or data.get('product_programme_dependency') is not False:
        errors.append('Invalid independent three-issue fast-track contract')
    items = data.get('issues',[])
    if [i.get('id') for i in items] != IDS:
        return errors+['Fast track must contain exactly CI-POC-001..003, maximum3']
    numbers=[]
    for index,item in enumerate(items):
        if item.get('depends_on') != ([] if index == 0 else [IDS[index-1]]):
            errors.append(item['id']+': invalid dependency or product prerequisite')
        for field in ['scope','acceptance','tests']:
            if not isinstance(item.get(field),list) or not item[field] or any(not isinstance(v,str) or not v.strip() for v in item[field]):
                errors.append(item['id']+': missing '+field)
        for field in ['title','excludes','status']:
            if not isinstance(item.get(field),str) or not item[field].strip():
                errors.append(item['id']+': missing '+field)
        number=item.get('issue_number')
        if isinstance(number,int) and not isinstance(number,bool) and number>0:
            numbers.append(number)
        elif require_published or number is not None:
            errors.append(item['id']+': unpublished/invalid number')
    if len(set(numbers)) != len(numbers):
        errors.append('Duplicate fast-track issue numbers')
    if errors:
        return errors
    for item in items:
        path=directory/(item['id']+'.md')
        if not path.is_file() or path.read_text(encoding='utf-8') != render_issue(item,data):
            errors.append('Stale/incomplete fast-track prompt '+item['id'])
    if not (directory/'README.md').is_file() or (directory/'README.md').read_text(encoding='utf-8') != render_index(data):
        errors.append('Stale fast-track index')
    for path in READING:
        if not (root/path).is_file():
            errors.append('Missing fast-track reading '+path)
    return errors

if __name__ == '__main__':
    render()
    print('Rendered three CI PoC issues; no GitHub or runtime actions.')
