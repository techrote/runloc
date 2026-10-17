"""Meaningful negative controls for the publication contract, not runtime tests."""
import copy
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from render_programme import load, render
from check_repository import check, validate_catalogue

class ProgrammeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name) / 'checkout with spaces'
        self.root.mkdir()
        shutil.copytree(ROOT / 'docs', self.root / 'docs')
        for name in ['README.md','AGENTS.md','LICENSE']:
            shutil.copy2(ROOT / name, self.root / name)
        self.data = load(self.root)

    def tearDown(self):
        self.temp.cleanup()

    def errors(self, data=None):
        return validate_catalogue(data or self.data, self.root, require_published=False)

    def test_complete_contract_and_spaces_path_pass(self):
        self.assertEqual(check(self.root, require_published=False), [])

    def test_cycle_or_forward_dependency_fails(self):
        self.data['issues'][0]['depends_on'] = ['RUNLOC-019']
        self.assertTrue(any('precede' in e or 'cycle' in e for e in self.errors()))

    def test_unknown_dependency_fails(self):
        self.data['issues'][0]['depends_on'] = ['RUNLOC-999']
        self.assertTrue(any('unknown dependency' in e for e in self.errors()))

    def test_duplicate_id_fails(self):
        self.data['issues'][1]['id'] = self.data['issues'][0]['id']
        self.assertTrue(self.errors())

    def test_missing_or_empty_acceptance_and_tests_fail(self):
        for field in ['scope','acceptance','tests','rag']:
            data = copy.deepcopy(self.data)
            data['issues'][0][field] = []
            self.assertTrue(any(field in e for e in self.errors(data)))

    def test_missing_and_escaping_rag_fail(self):
        for path in ['docs/rag/missing.md','../outside.md']:
            data = copy.deepcopy(self.data)
            data['issues'][0]['rag'] = [path]
            self.assertTrue(any('document' in e for e in self.errors(data)))

    def test_first_release_boundary_fails(self):
        self.data['first_release'].append('RUNLOC-015')
        self.assertTrue(any('First release' in e for e in self.errors()))

    def test_duplicate_published_numbers_fail(self):
        for item in self.data['issues']:
            item['issue_number'] = 1
        self.assertTrue(any('Duplicate published' in e for e in self.errors()))

    def test_unpublished_is_not_ci_success(self):
        self.data['issues'][0]['issue_number'] = None
        self.assertTrue(any('not published' in e for e in validate_catalogue(self.data, self.root)))

    def test_incomplete_prompt_is_detected(self):
        (self.root / 'docs/programme/issues/RUNLOC-001.md').write_text('A vague task', encoding='utf-8')
        self.assertTrue(any('mirror' in e for e in check(self.root, require_published=False)))

    def test_broken_markdown_link_is_detected(self):
        with (self.root / 'README.md').open('a', encoding='utf-8') as handle:
            handle.write('\n[missing](docs/no-such-file.md)\n')
        self.assertTrue(any('broken local link' in e for e in check(self.root, require_published=False)))

    def test_forbidden_runtime_artifact_is_detected(self):
        (self.root / 'docs/image.qcow2').write_bytes(b'fixture-not-a-real-image')
        self.assertTrue(any('Forbidden runtime' in e for e in check(self.root, require_published=False)))

    def test_regeneration_repairs_stale_mirror(self):
        (self.root / 'docs/programme/issues/RUNLOC-001.md').write_text('stale', encoding='utf-8')
        render(self.root)
        self.assertEqual(check(self.root, require_published=False), [])

if __name__ == '__main__':
    unittest.main()
