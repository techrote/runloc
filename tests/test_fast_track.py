"""Keep the immediate PoC bounded and independent of the full programme."""
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from fast_track import load, render, validate

class FastTrackTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory()
        self.root=Path(self.temp.name)/'checkout with spaces'
        self.root.mkdir()
        shutil.copytree(ROOT/'docs',self.root/'docs')
        shutil.copy2(ROOT/'AGENTS.md',self.root/'AGENTS.md')
        self.data=load(self.root)

    def tearDown(self):
        self.temp.cleanup()

    def write(self):
        (self.root/'docs/fast-track/issues.json').write_text(json.dumps(self.data),encoding='utf-8')

    def test_complete_three_issue_chain(self):
        self.assertEqual(validate(self.root,require_published=False),[])

    def test_fourth_issue_is_refused(self):
        self.data['issues'].append(dict(self.data['issues'][0],id='CI-POC-004'))
        self.write()
        self.assertTrue(any('maximum3' in e for e in validate(self.root,require_published=False)))

    def test_product_dependency_and_cycle_are_refused(self):
        for dep in ['RUNLOC-001','CI-POC-003']:
            self.data['issues'][0]['depends_on']=[dep]
            self.write()
            self.assertTrue(any('dependency' in e for e in validate(self.root,require_published=False)))

    def test_missing_acceptance_is_refused(self):
        self.data['issues'][0]['acceptance']=[]
        self.write()
        self.assertTrue(any('acceptance' in e for e in validate(self.root,require_published=False)))

    def test_stale_prompt_and_missing_contract_are_refused(self):
        (self.root/'docs/fast-track/CI-POC-001.md').write_text('vague task',encoding='utf-8')
        (self.root/'docs/fast-track/WINDOWS-WHPX-CI-POC.md').unlink()
        errors=validate(self.root,require_published=False)
        self.assertTrue(any('prompt' in e for e in errors))
        self.assertTrue(any('reading' in e for e in errors))

    def test_unpublished_does_not_pass_ci(self):
        self.data['issues'][0]['issue_number']=None
        self.write()
        self.assertTrue(any('unpublished' in e for e in validate(self.root)))

    def test_regeneration_preserves_three_prompts(self):
        (self.root/'docs/fast-track/CI-POC-001.md').write_text('stale',encoding='utf-8')
        render(self.root)
        self.assertEqual(validate(self.root,require_published=False),[])

if __name__=='__main__':
    unittest.main()
