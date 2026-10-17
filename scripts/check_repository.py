"""Offline contract check. Does not provision machines, install tools or call GitHub."""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlparse
from render_programme import COMMON, render_issue, render_index

ROOT = Path(__file__).resolve().parents[1]

def validate_catalogue(data: dict, root: Path, *, require_published: bool = True) -> list[str]:
    errors: list[str] = []
    if data.get('schema_version') != 1 or data.get('repository') != 'techrote/runloc':
        errors.append('Unsupported programme schema/repository')
    issues = data.get('issues', [])
    ids = [i.get('id') for i in issues]
    expected = [f'RUNLOC-{n:03}' for n in range(1,20)]
    if ids != expected:
        errors.append('Programme must contain unique topologically ordered RUNLOC-001..019')
    if data.get('first_release') != expected[:14]:
        errors.append('First release must explicitly contain RUNLOC-001..014')
    known = set(ids)
    numbers = []
    graph = {}
    for item in issues:
        code = item.get('id', '<missing>')
        for field in ['title', 'excludes', 'prerequisites']:
            if not isinstance(item.get(field), str) or not item[field].strip():
                errors.append(f'{code}: missing {field}')
        for field in ['scope', 'acceptance', 'tests', 'rag']:
            values = item.get(field)
            if not isinstance(values, list) or not values or any(not isinstance(v, str) or not v.strip() for v in values):
                errors.append(f'{code}: missing {field}')
        if item.get('status') not in {'planned','active','blocked','accepted'}:
            errors.append(f'{code}: invalid status')
        required_stage = 'v0.1' if code in expected[:14] else 'follow-on'
        if item.get('stage') != required_stage:
            errors.append(f'{code}: wrong stage')
        deps = item.get('depends_on', [])
        graph[code] = deps
        if not isinstance(deps, list) or len(deps) != len(set(deps)):
            errors.append(f'{code}: invalid dependencies')
            continue
        for dep in deps:
            if dep not in known:
                errors.append(f'{code}: unknown dependency {dep}')
            elif dep >= code:
                errors.append(f'{code}: dependency must precede issue: {dep}')
        for path in COMMON + item.get('rag', []):
            candidate = (root / path).resolve()
            if not candidate.is_relative_to(root.resolve()) or not candidate.is_file():
                errors.append(f'{code}: missing/escaping document {path}')
        number = item.get('issue_number')
        if number is not None:
            if not isinstance(number, int) or isinstance(number, bool) or number <= 0:
                errors.append(f'{code}: invalid issue number')
            else:
                numbers.append(number)
        elif require_published:
            errors.append(f'{code}: not published')
    if len(numbers) != len(set(numbers)):
        errors.append('Duplicate published issue number')
    visited, active = set(), set()
    def visit(code: str) -> None:
        if code in active:
            errors.append('Dependency cycle at ' + code)
            return
        if code in visited or code not in graph:
            return
        active.add(code)
        for dep in graph[code]:
            visit(dep)
        active.remove(code)
        visited.add(code)
    for code in graph:
        visit(code)
    return errors

def markdown_errors(root: Path) -> list[str]:
    errors = []
    for path in root.rglob('*.md'):
        if any(part in {'.git','runtime','.venv','__pycache__'} for part in path.relative_to(root).parts):
            continue
        for target in re.findall(r'(?<!!)\[[^\]]*\]\(([^\s)]+)\)', path.read_text(encoding='utf-8')):
            target = target.strip('<>')
            parsed = urlparse(target)
            if target.startswith('https://github.com/techrote/runloc/blob/main/'):
                candidate = root / unquote(parsed.path.split('/blob/main/',1)[1])
            elif parsed.scheme or target.startswith('#'):
                continue
            else:
                candidate = path.parent / unquote(parsed.path)
            if not candidate.resolve().is_relative_to(root.resolve()) or not candidate.exists():
                errors.append(f'{path.relative_to(root)}: broken local link {target}')
    return errors

def check(root: Path, *, require_published: bool = True) -> list[str]:
    errors = []
    for name in ['README.md','AGENTS.md','LICENSE','docs/programme/PLAN-REVIEW.md','docs/rag/README.md']:
        if not (root / name).is_file():
            errors.append('Missing required file ' + name)
    try:
        data = json.loads((root / 'docs/programme/issues.json').read_text(encoding='utf-8'))
    except (OSError, ValueError) as exc:
        return errors + [str(exc)]
    errors.extend(validate_catalogue(data, root, require_published=require_published))
    if errors:
        return errors
    for item in data['issues']:
        path = root / f'docs/programme/issues/{item["id"]}.md'
        if not path.is_file() or path.read_text(encoding='utf-8') != render_issue(item, data):
            errors.append('Stale or incomplete issue mirror ' + item['id'])
    index = root / 'docs/programme/IMPLEMENTATION-PROGRAMME.md'
    if not index.is_file() or index.read_text(encoding='utf-8') != render_index(data):
        errors.append('Stale programme index')
    errors.extend(markdown_errors(root))
    # Runtime artifacts/credential material must never become programme inputs.
    for path in (root / 'docs').rglob('*'):
        if path.is_file() and path.suffix.lower() in {'.qcow2','.iso','.pem','.key','.exe','.zip','.gz'}:
            errors.append('Forbidden runtime artifact ' + str(path.relative_to(root)))
    return errors

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, default=ROOT)
    parser.add_argument('--allow-unpublished', action='store_true', help='Local drafting only; CI requires publication')
    args = parser.parse_args()
    errors = check(args.root.resolve(), require_published=not args.allow_unpublished)
    if errors:
        print('\n'.join('FAIL: ' + e for e in errors), file=sys.stderr)
        return 1
    print('PASS: 19 issue contracts, first-release boundary, DAG, mirrors and repository links')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
