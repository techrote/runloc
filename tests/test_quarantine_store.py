"""Actual temporary-file recovery controls; no live API or qualifying receipts."""
from datetime import datetime, timezone
from pathlib import Path
import os
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'poc/windows-whpx'))
import quarantine_store as store
from qualification_gate import canonical, decide, digest, InvalidEvidence


class QuarantineStoreTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='runloc-failure-store-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.backing = self.root / 'private-backing'; self.backing.mkdir()
        self.source = self.root / 'committed-source'; self.source.mkdir()
        self.candidate = dict(commit='a'*40, tree='b'*40)
        self.old_candidate = dict(commit='c'*40, tree='d'*40)
        self.legacy = self.backing / store.LEGACY
        self.old = dict(schemaVersion=1, candidate=self.old_candidate, comparisonId='e'*32,
            private='unknown', hosted='pending', utc=datetime.now(timezone.utc).isoformat(), resetRequires='explicit-reviewed-reset')
        self.old_raw = canonical(self.old)
        self.baseline = dict(backingRootSha256=digest(os.path.normcase(str(self.backing.resolve())).encode()),
                             legacySha256=digest(self.old_raw))

    def blocked(self, recovery=None):
        return store.quarantine_blocked(self.backing, self.candidate, recovery, source_root=self.source, baseline=self.baseline)

    def recovery(self):
        self.legacy.write_bytes(self.old_raw)
        self.adjudication = dict(schemaVersion=1, candidate=self.candidate, legacySha256=digest(self.old_raw),
            backingRootSha256=digest(os.path.normcase(str(self.backing.resolve())).encode()),
            historicalCauseResolved=False, authorRole='Codex primary agent', reviewerRole='separate Codex agent',
            reason='Synthetic fixture: eligibility only; historical cause unresolved.', proofs=dict(
                physicalReceiptSha256='1'*64, hostedReceiptSha256='2'*64, physicalAttemptId='3'*32,
                hostedRunId=123, controllerCommit='4'*40, controllerTree='5'*40))
        self.adjudication_path = self.source / store.ADJUDICATION
        self.adjudication_path.parent.mkdir(parents=True)
        raw = canonical(self.adjudication); self.adjudication_path.write_bytes(raw)
        return dict(schemaVersion=1, candidate=self.candidate, legacySha256=digest(self.old_raw), adjudicationSha256=digest(raw),
                    backingRootSha256=self.adjudication['backingRootSha256'])

    def test_default_blocks_both_missing_and_retained_required_history(self):
        self.assertTrue(self.blocked())
        self.assertEqual('failure', decide('pending', 'pending', quarantined=self.blocked()))
        self.legacy.write_bytes(self.old_raw)
        self.assertTrue(self.blocked())

    def test_reviewed_exact_exemption_is_eligibility_not_acceptance(self):
        recovery = self.recovery()
        self.assertFalse(self.blocked(recovery))
        self.assertEqual('pending', decide('pending', 'pending', quarantined=self.blocked(recovery)))
        self.assertEqual(self.old_raw, self.legacy.read_bytes())

    def test_wrong_candidate_tree_schema_or_digest_never_exempts(self):
        recovery = self.recovery()
        variants = [recovery | {'candidate': self.old_candidate}, recovery | {'candidate': self.candidate | {'tree':'f'*40}},
                    recovery | {'schemaVersion':True}, recovery | {'legacySha256':'0'*64},
                    recovery | {'adjudicationSha256':'0'*64}, {}, True]
        for value in variants:
            with self.subTest(value=value): self.assertTrue(self.blocked(value))

    def test_missing_changed_malformed_or_unreadable_legacy_blocks_recovery(self):
        recovery = self.recovery()
        self.legacy.unlink()
        self.assertTrue(self.blocked(recovery))
        for raw in (b'{}', b'partial', self.old_raw+b'\n'):
            self.legacy.write_bytes(raw)
            self.assertTrue(self.blocked(recovery))
        self.legacy.write_bytes(self.old_raw)
        with patch.object(store, 'read_small', side_effect=PermissionError('synthetic access denied')):
            self.assertTrue(self.blocked(recovery))

    def test_another_empty_backing_cannot_evade_required_history(self):
        recovery = self.recovery()
        other = self.root / 'other'; other.mkdir()
        self.assertTrue(store.quarantine_blocked(other, self.candidate, recovery, source_root=self.source, baseline=self.baseline))
        (other/store.LEGACY).write_bytes(self.old_raw)
        self.assertTrue(store.quarantine_blocked(other, self.candidate, recovery, source_root=self.source, baseline=self.baseline))

    def test_baseline_is_required_even_without_recovery_and_before_history_exists(self):
        other = self.root / 'other-without-recovery'; other.mkdir()
        for backing in (self.backing, other):
            self.assertTrue(store.quarantine_blocked(backing, self.candidate, source_root=self.source, baseline=self.baseline))
        recovery = self.recovery()
        for baseline in (None, {}, True, self.baseline | {'legacySha256': '0'*64},
                         self.baseline | {'backingRootSha256': '0'*64}, self.baseline | {'extra': True}):
            with self.subTest(baseline=baseline):
                self.assertTrue(store.quarantine_blocked(self.backing, self.candidate, recovery,
                                                         source_root=self.source, baseline=baseline))
        self.assertTrue(store.quarantine_blocked(other, self.candidate, source_root=self.source, baseline=self.baseline))
        (other/store.LEGACY).write_bytes(self.old_raw)
        self.assertTrue(store.quarantine_blocked(other, self.candidate, source_root=self.source, baseline=self.baseline))

    def test_new_actual_failure_persists_despite_existing_exempt_legacy(self):
        recovery = self.recovery()
        with patch.object(store.os, 'fsync', wraps=os.fsync) as sync:
            store.record_failure(self.backing, self.candidate, '6'*32, 'pass', 'assertion')
            self.assertGreaterEqual(sync.call_count, 1)
        self.assertTrue(self.blocked(recovery))
        self.assertEqual(self.old_raw, self.legacy.read_bytes())
        self.assertEqual('assertion', store.validate_failure((self.backing/store.STORE/('6'*32+'.json')).read_bytes())['hosted'])

    def test_repeated_failure_preserves_first_bytes_across_restart(self):
        self.recovery()
        store.record_failure(self.backing, self.candidate, '6'*32, 'unknown', 'pending')
        path = self.backing/store.STORE/('6'*32+'.json'); first = path.read_bytes()
        store.record_failure(self.backing, self.candidate, '6'*32, 'pass', 'assertion')
        self.assertEqual(first, path.read_bytes())
        self.assertTrue(store.quarantine_blocked(self.backing, self.candidate, source_root=self.source, baseline=self.baseline))
        with self.assertRaisesRegex(InvalidEvidence, 'existing-failure-candidate'):
            store.record_failure(self.backing, self.old_candidate, '6'*32, 'unknown', 'pending')

    def test_first_failure_also_blocks_older_controllers_through_global_latch(self):
        store.record_failure(self.backing, self.candidate, '6'*32, 'cleanup', 'pass')
        self.assertTrue(self.legacy.exists())
        self.assertEqual((self.backing/store.STORE/('6'*32+'.json')).read_bytes(), self.legacy.read_bytes())
        self.assertTrue(self.blocked())

    def test_quarantine_only_failure_adds_no_poison_record(self):
        self.legacy.write_bytes(self.old_raw)
        self.assertEqual('failure', decide('pass', 'pass', quarantined=self.blocked()))
        store.record_failure(self.backing, self.candidate, '6'*32, 'pass', 'pass')
        self.assertFalse((self.backing/store.STORE).exists())
        self.assertEqual(self.old_raw, self.legacy.read_bytes())

    def test_unknown_partial_malformed_and_directory_entries_block(self):
        recovery = self.recovery()
        directory = self.backing/store.STORE; directory.mkdir()
        for name, raw in (('partial.new', b'partial'), ('6'*32+'.json', b'{}'), ('7'*32+'.json', b'x'*16385)):
            path = directory/name; path.write_bytes(raw)
            self.assertTrue(self.blocked(recovery)); path.unlink()
        (directory/('8'*32+'.json')).mkdir()
        self.assertTrue(self.blocked(recovery))

    def test_empty_store_preserves_failure_intent(self):
        recovery = self.recovery()
        (self.backing/store.STORE).mkdir()
        self.assertTrue(self.blocked(recovery))

    def test_write_failure_after_mkdir_cannot_leave_eligible_recovery(self):
        recovery = self.recovery()
        with patch.object(Path, 'open', side_effect=OSError('synthetic failure before durable record')):
            with self.assertRaises(OSError):
                store.record_failure(self.backing, self.candidate, '6'*32, 'unknown', 'pending')
        self.assertEqual([], list((self.backing/store.STORE).iterdir()))
        self.assertTrue(self.blocked(recovery))
        self.assertEqual(self.old_raw, self.legacy.read_bytes())

    def test_hardlinked_legacy_is_not_safe_history(self):
        recovery = self.recovery()
        os.link(self.legacy, self.root/'legacy-hardlink')
        self.assertTrue(self.blocked(recovery))

    def test_reparse_attribute_is_rejected(self):
        recovery = self.recovery()
        self.assertFalse(self.blocked(recovery))
        actual = self.legacy.lstat()
        from types import SimpleNamespace
        metadata = SimpleNamespace(st_file_attributes=0x400, st_mode=actual.st_mode, st_nlink=1)
        with patch.object(Path, 'lstat', return_value=metadata): self.assertTrue(self.blocked(recovery))

    def test_hardlink_created_between_path_check_and_opened_handle_is_rejected(self):
        recovery = self.recovery()
        original_open = Path.open
        def race(path, *args, **kwargs):
            if path == self.legacy:
                os.link(path, self.root/'raced-hardlink')
            return original_open(path, *args, **kwargs)
        with patch.object(Path, 'open', race): self.assertTrue(self.blocked(recovery))

    def test_deep_json_within_size_limit_blocks_each_history_input(self):
        recovery = self.recovery()
        deep = b'['*8000 + b']'*8000
        self.legacy.write_bytes(deep)
        self.assertTrue(self.blocked(recovery))
        self.legacy.write_bytes(self.old_raw)
        self.adjudication_path.write_bytes(deep)
        self.assertTrue(self.blocked(recovery | {'adjudicationSha256':digest(deep)}))
        self.adjudication_path.write_bytes(canonical(self.adjudication))
        directory = self.backing/store.STORE; directory.mkdir()
        (directory/('6'*32+'.json')).write_bytes(deep)
        self.assertTrue(self.blocked(recovery))

    def test_adjudication_roles_history_and_proof_shapes_fail_closed(self):
        recovery = self.recovery()
        variants = [self.adjudication | {'historicalCauseResolved':True}, self.adjudication | {'reviewerRole':'self review'},
                    self.adjudication | {'proofs':self.adjudication['proofs'] | {'hostedRunId':True}},
                    self.adjudication | {'proofs':self.adjudication['proofs'] | {'physicalReceiptSha256':'bad'}},
                    self.adjudication | {'extra':'unknown'}]
        for value in variants:
            raw = canonical(value); self.adjudication_path.write_bytes(raw)
            with self.subTest(value=value): self.assertTrue(self.blocked(recovery | {'adjudicationSha256':digest(raw)}))


if __name__ == '__main__': unittest.main()
