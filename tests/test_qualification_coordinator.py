"""Offline coordinator recovery and authoritative-publication controls; no live API."""
from contextlib import nullcontext
from datetime import datetime, timezone
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1] / 'poc/windows-whpx'
sys.path.insert(0, str(SOURCE))
try:
    import qualification_coordinator as coordinator
finally:
    sys.path.pop(0)


class CoordinatorTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix='runloc-coordinator-test-')
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.policy = coordinator.load(SOURCE / 'gate-policy.json')
        self.path = self.root / 'state.json'
        self.path.write_bytes(coordinator.canonical(dict(policy=self.policy, policySha256=coordinator.digest(coordinator.canonical(self.policy)),
            candidate=self.policy['candidate'], gateController={'commit': 'a'*40}, backingRoot=str(self.root),
            selection='available', comparisonId='b'*32, createdUtc=datetime.now(timezone.utc).isoformat())))
        self.state = coordinator.State(self.path)
        self.controller = coordinator.Coordinator(self.state)

    def test_state_policy_cannot_enable_or_change_committed_policy(self):
        self.state.value['policy'] = self.policy | {'executionApproved': not self.policy['executionApproved']}
        self.controller.policy = self.state.value['policy']
        with self.assertRaisesRegex(coordinator.InvalidEvidence, 'state-policy-not-committed'):
            self.controller.source()

    def test_no_private_attempt_before_confirmed_hosted_run(self):
        with self.assertRaisesRegex(coordinator.InvalidEvidence, 'hosted-must-start-first'):
            self.controller.start_private()
        self.assertNotIn('private', self.state.value)

    def test_uncertain_private_start_is_never_replayed(self):
        self.state.value.update(hosted={'runId': 12}, private={'outcome': 'pending', 'startupAttempted': True})
        with patch.object(coordinator, 'run_powershell', side_effect=AssertionError('duplicate startup')):
            self.controller.start_private()
        self.assertEqual('unknown', self.controller.observe_private()[0])

    def test_hosted_only_does_not_launch_registration(self):
        self.state.value.update(hosted={'runId': 12}, selection='hosted-only')
        with patch.object(coordinator, 'run_powershell', side_effect=AssertionError('unexpected registration')):
            self.controller.start_private()
        self.assertEqual('hosted-only', self.controller.observe_private()[0])

    def test_quarantine_survives_restart_and_blocks_private_start(self):
        self.state.value['hosted'] = {'runId': 12}
        (self.root / 'ci-poc-003-private-quarantine.json').write_text('{}')
        with patch.object(coordinator, 'run_powershell', side_effect=AssertionError('quarantined registration')):
            self.controller.start_private()
        self.assertEqual('security', self.controller.observe_private()[0])

    def test_late_hosted_failure_revokes_and_new_green_cannot_clear_latch(self):
        with patch.object(coordinator, 'exclusive', return_value=nullcontext()), \
             patch.object(self.controller, 'source'), \
             patch.object(coordinator, 'create_ledger_once', return_value={'url': 'https://example.invalid/proof'}) as ledger, \
             patch.object(coordinator, 'publish_status_once') as status:
            self.assertEqual('accepted-whpx', self.controller.publish('pass', {}, 'pending', {}))
            self.assertEqual('failure', self.controller.publish('pass', {}, 'assertion', {}))
            self.assertTrue((self.root / 'ci-poc-003-private-quarantine.json').exists())
            self.assertEqual('failure', self.controller.publish('pass', {}, 'pass', {}))
            self.assertEqual('failure', status.call_args.kwargs['outcome'])

    def test_unapproved_gate_cannot_dispatch(self):
        self.controller.policy = self.policy | {'executionApproved': False}
        with patch.object(self.controller, 'start_hosted', side_effect=AssertionError('unapproved dispatch')):
            with self.assertRaisesRegex(coordinator.InvalidEvidence, 'gate-execution-not-approved'):
                self.controller.run()

    def test_merge_verifier_requires_completed_acceptance(self):
        with patch.object(self.controller, 'source'):
            with self.assertRaisesRegex(coordinator.InvalidEvidence, 'comparison-not-accepted'):
                self.controller.verify_for_merge()

    def test_ambiguous_hosted_start_stays_observational_until_reconciled(self):
        self.controller.policy = self.policy | {'executionApproved': True}
        calls = []
        def hosted():
            calls.append('hosted')
            if len(calls) == 1:
                self.state.value['hosted'] = {'writeState': 'unknown', 'intent': {}}
                self.state.save()
                raise coordinator.UnknownWrite('no-match-yet')
            self.state.value['hosted']['runId'] = 12
            return 12
        def private():
            self.assertEqual(12, self.state.value['hosted']['runId'])
            calls.append('private')
        with patch.object(self.controller, 'source'), patch.object(self.controller, 'start_hosted', side_effect=hosted), \
             patch.object(self.controller, 'start_private', side_effect=private), \
             patch.object(self.controller, 'observe_hosted', return_value=('pass', {})), \
             patch.object(self.controller, 'observe_private', return_value=('hosted-only', {})), \
             patch.object(self.controller, 'publish', return_value='accepted-tcg'), patch.object(coordinator.time, 'sleep'):
            self.assertEqual(0, self.controller.run())
        self.assertEqual(['hosted', 'hosted', 'private'], calls)

    def test_torn_local_snapshot_is_unavailable_not_a_permanent_verdict(self):
        path = self.root / 'event-000001.json'; path.write_text('{')
        with patch.object(coordinator.time, 'sleep'):
            with self.assertRaises(coordinator.UnknownWrite): coordinator.snapshot(path)
        path.write_text('{"kind":"registered"}')
        self.assertEqual({'kind': 'registered'}, coordinator.snapshot(path))


if __name__ == '__main__':
    unittest.main()
