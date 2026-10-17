"""Explicitly publish/reconcile the reviewed catalogue using existing gh authorization.

Dry-run is default. --apply creates/updates issues, never starts implementation.
After an unknown write outcome, rerun to observe exact existing issue IDs first.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import re
import subprocess
from render_programme import ROOT, load, render, render_issue
from check_repository import check

REPO = 'techrote/runloc'

def gh(*args: str) -> str:
    result = subprocess.run(['gh', *args], cwd=ROOT, text=True, encoding='utf-8',
                            capture_output=True, timeout=120)
    if result.returncode:
        raise RuntimeError(f'GitHub command failed; reconcile before retry: {result.stderr.strip()}')
    return result.stdout.strip()

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    errors = check(ROOT, require_published=False)
    if errors:
        raise SystemExit('\n'.join(errors))
    data = load()
    if not args.apply:
        print(f'DRY RUN: {len(data["issues"])} reviewed issue bodies; use --apply to publish to {REPO}')
        return 0
    remote = json.loads(gh('repo','view',REPO,'--json','nameWithOwner,viewerPermission'))
    if remote['nameWithOwner'] != REPO or remote['viewerPermission'] not in {'ADMIN','MAINTAIN','WRITE'}:
        raise SystemExit('Wrong repository or missing existing write authorization')
    existing = json.loads(gh('issue','list','--repo',REPO,'--state','all','--limit','1000','--json','number,title,url'))
    lookup = {}
    for issue in existing:
        match = re.match(r'^\[(RUNLOC-\d{3})\]', issue['title'])
        if match:
            code = match.group(1)
            if code in lookup:
                raise SystemExit('Duplicate remote programme issue: ' + code)
            lookup[code] = issue
    labels = {x['name'] for x in json.loads(gh('label','list','--repo',REPO,'--limit','1000','--json','name'))}
    for name, color, description in [('programme','1D76DB','Reviewed autonomous implementation programme'),
                                     ('v0.1','0E8A16','First-release dependency programme'),
                                     ('follow-on','5319E7','Separately gated post-v0.1 work')]:
        if name not in labels:
            gh('label','create',name,'--repo',REPO,'--color',color,'--description',description)
    runtime = ROOT / 'runtime/publication'
    runtime.mkdir(parents=True, exist_ok=True)
    journal = runtime / 'writes.jsonl'
    def record(value: dict) -> None:
        with journal.open('a', encoding='utf-8') as handle:
            handle.write(json.dumps(value) + '\n')
    for item in data['issues']:
        code = item['id']
        body = runtime / f'{code}.md'
        body.write_text(render_issue(item, data), encoding='utf-8')
        if code not in lookup:
            record({'operation':'create-intent','id':code})
            link = gh('issue','create','--repo',REPO,'--title',f'[{code}] {item["title"]}',
                      '--body-file',str(body),'--label','programme','--label',item['stage'])
            match = re.fullmatch(r'https://github.com/techrote/runloc/issues/(\d+)',link)
            if not match:
                raise SystemExit('Unknown create response; observe remote state before retry')
            lookup[code] = {'number':int(match.group(1)), 'url':link}
            record({'operation':'created','id':code,'url':link})
        number = lookup[code]['number']
        if item.get('issue_number') not in {None, number}:
            raise SystemExit('Published number mismatch for ' + code)
        item['issue_number'] = number
        (ROOT / 'docs/programme/issues.json').write_text(json.dumps(data, indent=2)+'\n', encoding='utf-8')
        print(code, lookup[code]['url'], flush=True)
    render()
    for item in data['issues']:
        body = ROOT / f'docs/programme/issues/{item["id"]}.md'
        record({'operation':'update-intent','id':item['id'],'number':item['issue_number']})
        gh('issue','edit',str(item['issue_number']),'--repo',REPO,'--body-file',str(body))
        record({'operation':'updated','id':item['id'],'number':item['issue_number']})
    errors = check(ROOT)
    if errors:
        raise SystemExit('\n'.join(errors))
    print('Published and linked all 19 issues; implementation remains unstarted.')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
