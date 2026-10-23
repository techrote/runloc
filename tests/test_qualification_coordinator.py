"""Offline coordinator recovery and authoritative-publication controls; no live API."""
from contextlib import nullcontext
from datetime import datetime, timedelta, timezone
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
from types import SimpleNamespace

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

    def test_observer_loads_writable_state_only_after_exclusive_lock(self):
        fresh = object()
        events = []
        def read_state(path):
            if events: self.assertEqual('acquired', events[-1])
            events.append('read')
            return self.state if len(events) == 1 else fresh
        fake_native = SimpleNamespace(LK_NBLCK=1, LK_UNLCK=2,
            locking=lambda descriptor, mode, count: events.append('acquired' if mode == 1 else 'released'))
        with patch.object(coordinator.sys, 'argv', ['coordinator', '--state', str(self.path)]), \
             patch.object(coordinator.sys, 'platform', 'win32'), \
             patch.dict(sys.modules, {'msvcrt': fake_native}), \
             patch.object(coordinator, 'State', side_effect=read_state), \
             patch.object(coordinator, 'Coordinator') as constructor:
            constructor.return_value.run.return_value = 0
            self.assertEqual(0, coordinator.main())
            constructor.assert_called_once_with(fresh)
        self.assertEqual(['read', 'acquired', 'read', 'released'], events)

    def test_no_private_attempt_before_confirmed_hosted_run(self):
        with self.assertRaisesRegex(coordinator.InvalidEvidence, 'hosted-must-start-first'):
            self.controller.start_private()
        self.assertNotIn('private', self.state.value)

    def test_run_job_api_responses_must_bind_exact_positive_ids_and_repository(self):
        pin = self.policy['private']
        run = dict(id=13, repository={'full_name': 'techrote/ezvm'}, head_sha=pin['workflowCommit'],
            path=pin['workflowPath'], display_title='CI-PoC002 '+'c'*32, event='workflow_dispatch',
            run_attempt=1, actor={'login': 'techrote'})
        job = dict(id=14, run_id=13)
        def observe(returned_run, returned_job):
            with patch.object(self.controller.api, 'request', side_effect=[(200, returned_run),
                (200, {'total_count': int(returned_job is not None), 'jobs': [] if returned_job is None else [returned_job]})]):
                return self.controller.association('private', 13, 'c'*32)
        self.assertEqual((run, job), observe(run, job))
        self.assertEqual((run, None), observe(run, None))
        for changed in ({'id': 99}, {'id': True}, {'id': None}, {'repository': {'full_name': 'other/ezvm'}}):
            with self.subTest(run=changed), self.assertRaises(coordinator.InvalidEvidence): observe(run | changed, job)
        for changed in ({'id': 0}, {'id': True}, {'id': None}, {'run_id': 99}, {'run_id': True}, {'run_id': None}):
            with self.subTest(job=changed), self.assertRaises(coordinator.InvalidEvidence): observe(run, job | changed)
        for target in (run, job):
            missing = {key: value for key, value in target.items() if key != 'id'}
            with self.subTest(missing=target), self.assertRaises((coordinator.InvalidEvidence, KeyError)):
                observe(missing, job) if target is run else observe(run, missing)
        with self.assertRaises(coordinator.InvalidEvidence): self.controller.association('private', True, 'c'*32)

    def test_uncertain_private_start_is_never_replayed(self):
        self.state.value.update(hosted={'runId': 12}, private={'outcome': 'pending', 'startupAttempted': True})
        with patch.object(coordinator, 'run_powershell', side_effect=AssertionError('duplicate startup')):
            self.controller.start_private()
        self.assertEqual('unknown', self.controller.observe_private()[0])

    def private_final_fixture(self, reason='no-job-deadline'):
        lease_id = 'd'*32
        lease = self.root / ('runloc-whpx-'+lease_id); lease.mkdir()
        # Hosted Windows TEMP can contain RUNNER~1. Ownership records require
        # the same canonical spelling that the real observer resolves.
        lease = lease.resolve()
        console = self.root / 'console-test'; console.mkdir()
        (console / 'controller.stdout.log').write_text('RUNLOC_RUNNER_LEASE='+str(lease)+'\n')
        owner = dict(leaseId=lease_id, root=str(lease), controllerCommit=self.policy['private']['hostController'],
                     candidateCommit=self.policy['candidate']['commit'], createdUtc=self.state.value['createdUtc'])
        (lease / 'lease.json').write_bytes(coordinator.canonical(owner))
        final = dict(passed=False, reason=reason, runId=13, runnerId=48, registrationAbsent=True, activeProcesses=0,
                     fixtureRemoved=True, controllerUnchanged=True, reusableBackingPreserved=True, unrelatedSentinelSurvived=True)
        (lease / 'event-000001.json').write_bytes(coordinator.canonical(dict(kind='dispatched', data={'runId': 13})))
        (lease / 'event-000002.json').write_bytes(coordinator.canonical(dict(kind='final', data=final)))
        ended = dict(exitObserved=True, exitCode=1, endedUtc=datetime.now(timezone.utc).isoformat())
        (console / 'controller-ended.json').write_bytes(coordinator.canonical(ended))
        self.state.value.update(selection='loss-before-harness' if reason == 'owner-cancelled' else 'available',
            private={'outcome': 'pending', 'console': str(console), 'stopIntentUtc': self.state.value['createdUtc']})
        run = dict(id=13, status='completed', conclusion='cancelled')
        job = dict(id=14, run_id=13, status='completed', conclusion='cancelled', runner_id=0, runner_name='', labels=['runloc-'+lease_id], steps=[])
        return run, job, console, ended

    def test_queue_expired_requires_api_nonexecution_and_cannot_hide_failed_assertion(self):
        run, job, _, _ = self.private_final_fixture()
        with patch.object(self.controller.api, 'request', return_value=(404, None)), \
             patch.object(self.controller, 'association', return_value=(run, job)):
            self.assertEqual('queue-expired', self.controller.observe_private()[0])
            job.update(runner_id=48, runner_name='runloc-'+'d'*32, conclusion='failure',
                steps=[dict(name='Exact preflight and full original six-CPU WHPX qualification', status='completed', conclusion='failure')])
            run['conclusion'] = 'failure'
            with self.assertRaises(coordinator.InvalidEvidence): self.controller.observe_private()

    def test_loss_control_accepts_positive_unassigned_proof_and_bounds_api_settling(self):
        run, job, console, ended = self.private_final_fixture('owner-cancelled')
        with patch.object(self.controller.api, 'request', return_value=(404, None)), \
             patch.object(self.controller, 'association', return_value=(run, job)):
            self.assertEqual('cancelled-before-harness', self.controller.observe_private()[0])
            run.update(status='queued', conclusion=None)
            self.assertEqual('pending', self.controller.observe_private()[0])
            ended['endedUtc'] = (datetime.now(timezone.utc)-timedelta(seconds=121)).isoformat()
            (console / 'controller-ended.json').write_bytes(coordinator.canonical(ended))
            with self.assertRaisesRegex(coordinator.InvalidEvidence, 'cancellation-unresolved'):
                self.controller.observe_private()

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

    def test_writable_policy_cannot_enable_recovery_or_change_eligible_candidate(self):
        self.assertFalse(self.controller.quarantined())
        self.controller.policy = self.policy | {'recovery': {'schemaVersion': 1}}
        self.assertTrue(self.controller.quarantined())
        self.controller.policy = self.policy
        self.state.value['candidate'] = {'commit': 'f'*40, 'tree': 'e'*40}
        self.assertTrue(self.controller.quarantined())

    def test_publication_records_new_failure_with_legacy_present_but_not_quarantine_only_failure(self):
        legacy = self.root / 'ci-poc-003-private-quarantine.json'
        legacy.write_bytes(b'{}')  # Unknown retained history must continue blocking.
        with patch.object(coordinator, 'exclusive', return_value=nullcontext()), \
             patch.object(self.controller, 'source'), \
             patch.object(coordinator, 'create_ledger_once', return_value={'url': 'https://example.invalid/proof'}), \
             patch.object(coordinator, 'publish_status_once'):
            self.assertEqual('failure', self.controller.publish('pass', {}, 'pass', {}))
            self.assertFalse((self.root / 'ci-poc-003-failures').exists())
            self.assertEqual('failure', self.controller.publish('pass', {}, 'assertion', {}))
            record = self.root / 'ci-poc-003-failures' / ('b'*32+'.json')
            first = record.read_bytes()
            self.assertEqual('assertion', coordinator.json_bytes(first)['hosted'])
            self.assertEqual('failure', self.controller.publish('unknown', {}, 'pending', {}))
            self.assertEqual(first, record.read_bytes())
            self.assertEqual(b'{}', legacy.read_bytes())

    def test_late_failure_revokes_success_even_when_existing_failure_store_is_malformed(self):
        with patch.object(coordinator, 'exclusive', return_value=nullcontext()), \
             patch.object(self.controller, 'source'), \
             patch.object(coordinator, 'create_ledger_once', return_value={'url': 'https://example.invalid/proof'}) as ledger, \
             patch.object(coordinator, 'publish_status_once') as status:
            self.assertEqual('accepted-whpx', self.controller.publish('pass', {}, 'pending', {}))
            directory = self.root / 'ci-poc-003-failures'; directory.mkdir()
            malformed = directory / ('c'*32+'.json'); malformed.write_bytes(b'{')
            self.assertEqual('failure', self.controller.publish('pass', {}, 'assertion', {}))
            self.assertEqual('failure', status.call_args.kwargs['outcome'])
            failure = ledger.call_args.args[2]
            self.assertTrue(failure['failurePersistence']['blockedHistoryRetained'])
            self.assertEqual(b'{', malformed.read_bytes())
            self.assertEqual('failure', self.controller.publish('pass', {}, 'pass', {}))
            self.assertEqual('failure', status.call_args.kwargs['outcome'])
            self.assertEqual(b'{', malformed.read_bytes())

    def test_unresolved_failure_write_without_blocking_history_stops_before_publication(self):
        with patch.object(coordinator, 'exclusive', return_value=nullcontext()), \
             patch.object(coordinator, 'record_failure', side_effect=OSError('synthetic disk failure')), \
             patch.object(coordinator, 'publish_status_once') as status:
            with self.assertRaisesRegex(RuntimeError, 'failure-persistence-unresolved-stop'):
                self.controller.publish('pass', {}, 'assertion', {})
            status.assert_not_called()
        self.assertTrue(self.controller.state.value['failurePersistenceUnresolved'])

    def test_unresolved_observed_failure_survives_restart_and_retries_original_failure_not_later_green(self):
        with patch.object(coordinator, 'exclusive', return_value=nullcontext()), \
             patch.object(coordinator, 'record_failure', side_effect=OSError('synthetic disk failure')):
            with self.assertRaisesRegex(RuntimeError, 'failure-persistence-unresolved-stop'):
                self.controller.publish('unknown', {}, 'pending', {})
        resumed = coordinator.Coordinator(coordinator.State(self.path))
        self.assertTrue(resumed.quarantined())
        with patch.object(coordinator, 'exclusive', return_value=nullcontext()), \
             patch.object(resumed, 'source'), \
             patch.object(coordinator, 'create_ledger_once', return_value={'url': 'https://example.invalid/proof'}), \
             patch.object(coordinator, 'publish_status_once') as status:
            self.assertEqual('failure', resumed.publish('pass', {}, 'pass', {}))
            self.assertEqual('failure', status.call_args.kwargs['outcome'])
        record = coordinator.load(self.root/'ci-poc-003-failures'/('b'*32+'.json'))
        self.assertEqual(('unknown', 'pending'), (record['private'], record['hosted']))
        resumed.state.value['lastOutcome'] = 'accepted-whpx'  # A stale visible success still cannot verify.
        with patch.object(resumed, 'source'), patch.object(resumed, 'observe_private', return_value=('pass', {})), \
             patch.object(resumed, 'observe_hosted', return_value=('pass', {})):
            with self.assertRaisesRegex(coordinator.InvalidEvidence, 'acceptance-no-longer-valid'):
                resumed.verify_for_merge()

    def test_any_malformed_unresolved_marker_blocks_comparison(self):
        for marker in (False, None, {}, 'invalid'):
            self.state.value['failurePersistenceUnresolved'] = marker
            self.assertTrue(self.controller.quarantined())

    def test_actual_prestart_quarantine_refusal_does_not_poison_recovery_but_hosted_failure_persists(self):
        self.state.value['hosted'] = {'runId': 12}
        legacy = self.root / 'ci-poc-003-private-quarantine.json'; legacy.write_bytes(b'{}')
        with patch.object(coordinator, 'run_powershell', side_effect=AssertionError('quarantined registration')):
            self.controller.start_private()
        private, proof = self.controller.observe_private()
        self.assertEqual('security', private)
        with patch.object(coordinator, 'exclusive', return_value=nullcontext()), \
             patch.object(self.controller, 'source'), \
             patch.object(coordinator, 'create_ledger_once', return_value={'url': 'https://example.invalid/proof'}), \
             patch.object(coordinator, 'publish_status_once'):
            self.assertEqual('failure', self.controller.publish(private, proof, 'pending', {}))
            self.assertFalse((self.root / 'ci-poc-003-failures').exists())
            self.assertEqual('failure', self.controller.publish(private, proof, 'assertion', {}))
            record = coordinator.load(self.root / 'ci-poc-003-failures' / ('b'*32+'.json'))
            self.assertEqual(('pending', 'assertion'), (record['private'], record['hosted']))
            self.assertEqual(b'{}', legacy.read_bytes())

    def test_genuine_private_security_cannot_impersonate_prestart_quarantine_refusal(self):
        with patch.object(coordinator, 'exclusive', return_value=nullcontext()), \
             patch.object(self.controller, 'source'), \
             patch.object(coordinator, 'create_ledger_once', return_value={'url': 'https://example.invalid/proof'}), \
             patch.object(coordinator, 'publish_status_once'):
            for index, changed in enumerate(({'runId':123}, {'quarantineOnly':1}, {'quarantineOnly':False}, {'reason':'new-security-failure'})):
                comparison = 'c'*31+str(index)
                self.state.value['comparisonId'] = comparison
                self.state.value['private'] = dict(outcome='security', reason='persistent-private-quarantine', quarantineOnly=True) | changed
                self.controller.publish('security', {'reason':'persistent-private-quarantine'}, 'pending', {})
                record = coordinator.load(self.root / 'ci-poc-003-failures' / (comparison+'.json'))
                self.assertEqual('security', record['private'])

    def test_absence_never_treats_api_error_partial_inventory_or_matching_label_as_absent(self):
        class API:
            def request(inner, method, endpoint):
                return inner.response
        api = API(); self.controller.api = api
        for response in ((403, {}), (200, {'total_count': 101, 'runners': []}),
                         (200, {'total_count': 1, 'runners': [{'name': 'other', 'labels': [{'name': 'runloc-test'}]}]})):
            api.response = response
            with self.subTest(response=response), self.assertRaises(coordinator.InvalidEvidence):
                self.controller.absent_inventory('runloc-test')
        api.response = (200, {'total_count': 0, 'runners': []})
        self.assertEqual(0, self.controller.absent_inventory('runloc-test')['eligibleCount'])

    def test_absence_dispatch_reconciles_same_intent_without_any_registration(self):
        self.state.value.update(selection='absent-capacity', hosted={'runId': 12})
        calls = []
        def dispatch(*args, **kwargs):
            calls.append(kwargs)
            if len(calls) == 1:
                self.state.value['absentDispatch'] = {'intent': self.controller.absence_dispatch_intent(self.state.value['private']),
                                                     'writeState': 'unknown'}
                self.state.save()
                raise coordinator.UnknownWrite('ambiguous')
            return 13
        with patch.object(self.controller, 'definition'), \
             patch.object(self.controller, 'source'), \
             patch.object(self.controller, 'absent_inventory', return_value={'eligibleCount': 0}) as inventory, \
             patch.object(coordinator, 'dispatch_once', side_effect=dispatch), \
             patch.object(coordinator, 'run_powershell', side_effect=AssertionError('registration not permitted')):
            with self.assertRaises(coordinator.UnknownWrite): self.controller.start_private()
            self.controller.start_private()
            self.assertEqual(calls[0], calls[1])
            self.assertEqual(13, self.state.value['private']['runId'])
            self.assertFalse(self.state.value['private']['registrationRequested'])
            inventory.assert_called_once()

    def test_absence_cannot_bypass_existing_quarantine(self):
        self.state.value.update(selection='absent-capacity', hosted={'runId': 12})
        (self.root / 'ci-poc-003-private-quarantine.json').write_text('{}')
        with patch.object(coordinator, 'dispatch_once', side_effect=AssertionError('quarantine bypass')):
            self.controller.start_private()
        self.assertEqual('security', self.controller.observe_private()[0])

    def test_absence_resume_before_api_intent_rechecks_quarantine_and_definition(self):
        self.absence_fixture()
        self.state.value['private'].pop('runId')
        self.state.value.pop('absentDispatch')
        (self.root / 'ci-poc-003-private-quarantine.json').write_text('{}')
        with patch.object(self.controller, 'source'), \
             patch.object(coordinator, 'dispatch_once', side_effect=AssertionError('first POST after quarantine')):
            with self.assertRaisesRegex(coordinator.InvalidEvidence, 'quarantined-before-dispatch'):
                self.controller.start_private()
        (self.root / 'ci-poc-003-private-quarantine.json').unlink()
        with patch.object(self.controller, 'source'), \
             patch.object(self.controller, 'definition', side_effect=coordinator.InvalidEvidence('moved-tag')), \
             patch.object(coordinator, 'dispatch_once', side_effect=AssertionError('first POST after moved tag')):
            with self.assertRaisesRegex(coordinator.InvalidEvidence, 'moved-tag'):
                self.controller.start_private()

    def test_absence_empty_api_intent_and_broad_label_cannot_dispatch(self):
        for changed in ('empty-api-intent', 'broad-label'):
            self.absence_fixture()
            self.state.value['private'].pop('runId')
            if changed == 'empty-api-intent': self.state.value['absentDispatch'] = {}
            else: self.state.value['private']['runnerName'] = 'self-hosted'
            with self.subTest(changed=changed), \
                 patch.object(coordinator, 'dispatch_once', side_effect=AssertionError('invalid intent POST')), \
                 self.assertRaises(coordinator.InvalidEvidence):
                self.controller.start_private()

    def absence_fixture(self, seconds=0):
        queued = datetime.now(timezone.utc) - timedelta(seconds=seconds)
        self.state.value.update(selection='absent-capacity', hosted={'runId': 12},
            private={'outcome': 'pending', 'absenceIntent': True, 'registrationRequested': False,
                     'comparisonId': 'c'*32, 'runnerName': 'runloc-'+'c'*32, 'runId': 13,
                     'startIntentUtc': queued.isoformat(), 'queuedObservedUtc': queued.isoformat(),
                     'initialInventory': {'eligibleCount': 0}})
        run = {'id': 13, 'status': 'queued', 'created_at': self.state.value['createdUtc']}
        pin = self.policy['private']
        self.state.value['absentDispatch'] = {'runId': 13, 'writeState': 'confirmed', 'intent': dict(
            path=pin['workflowPath'].rsplit('/', 1)[-1], commit=pin['workflowCommit'], ref=pin['workflowRef'],
            comparison='c'*32, title='CI-PoC002 '+'c'*32,
            inputs={'comparison_id': 'c'*32, 'runner_name': 'runloc-'+'c'*32, 'mode': 'qualification'})}
        job = {'id': 14, 'runner_id': 0, 'runner_name': '', 'steps': [], 'status': 'queued', 'labels': ['runloc-'+'c'*32]}
        return run, job

    def test_absence_queue_bound_cancels_only_owned_private_run_and_never_starts_console(self):
        run, job = self.absence_fixture(seconds=601)
        with patch.object(self.controller, 'absent_inventory', return_value={'eligibleCount': 0}), \
             patch.object(self.controller, 'association', return_value=(run, job)), \
             patch.object(coordinator, 'cancel_private_once') as cancel, \
             patch.object(coordinator, 'run_powershell', side_effect=AssertionError('registration not permitted')):
            self.assertEqual('pending', self.controller.observe_private()[0])
            cancel.assert_called_once_with(self.state, self.controller.api, 13)
        self.assertIn('cancelRequestedUtc', self.state.value['private'])

    def test_absence_cannot_hide_assigned_job_or_executed_step(self):
        run, job = self.absence_fixture()
        for changed in ({'runner_id': 48}, {'runner_id': False}, {'runner_name': 'assigned'},
                        {'steps': [{'conclusion': 'failure'}]}, {'steps': None}, {'labels': ['other']},
                        {'status': 'in_progress'}):
            with self.subTest(changed=changed), \
                 patch.object(self.controller, 'absent_inventory', return_value={'eligibleCount': 0}), \
                 patch.object(self.controller, 'association', return_value=(run, job | changed)), \
                 self.assertRaises(coordinator.InvalidEvidence):
                self.controller.observe_private()
        del job['steps']
        with patch.object(self.controller, 'absent_inventory', return_value={'eligibleCount': 0}), \
             patch.object(self.controller, 'association', return_value=(run, job)), \
             self.assertRaises(coordinator.InvalidEvidence):
            self.controller.observe_private()

    def test_absence_terminal_proof_is_durable_and_revalidated(self):
        run, job = self.absence_fixture(seconds=601)
        private = self.state.value['private']
        private.update(cancelIntent={'runId': 13}, cancelRequestedUtc=datetime.now(timezone.utc).isoformat())
        run.update(status='completed', conclusion='cancelled')
        job.update(status='completed', conclusion='cancelled')
        with patch.object(self.controller, 'absent_inventory', side_effect=[{'eligibleCount': 0, 'observedUtc': 'first'},
                                                                         {'eligibleCount': 0, 'observedUtc': 'second'}]), \
             patch.object(self.controller, 'association', return_value=(run, job)):
            outcome, proof = self.controller.observe_private()
            self.assertEqual('absent', outcome)
            self.controller.read_only = True
            self.assertEqual((outcome, proof), self.controller.observe_private())

    def test_absence_unrequested_or_early_cancellation_is_failure(self):
        run, job = self.absence_fixture(seconds=10)
        run.update(status='completed', conclusion='cancelled')
        job.update(status='completed', conclusion='cancelled')
        with patch.object(self.controller, 'absent_inventory', return_value={'eligibleCount': 0}), \
             patch.object(self.controller, 'association', return_value=(run, job)):
            with self.assertRaises(coordinator.InvalidEvidence): self.controller.observe_private()
            self.state.value['private'].update(cancelIntent={'runId': 13}, cancelRequestedUtc=datetime.now(timezone.utc).isoformat())
            with self.assertRaisesRegex(coordinator.InvalidEvidence, 'before-deadline'): self.controller.observe_private()

    def test_absence_non_atomic_cancel_observations_settle_without_accepting(self):
        for run_done in (False, True):
            run, job = self.absence_fixture(seconds=601)
            self.state.value['private'].update(cancelIntent={'runId': 13}, cancelRequestedUtc=datetime.now(timezone.utc).isoformat())
            if run_done: run.update(status='completed', conclusion='cancelled')
            else: job.update(status='completed', conclusion='cancelled')
            with self.subTest(run_done=run_done), \
                 patch.object(self.controller, 'absent_inventory', return_value={'eligibleCount': 0}), \
                 patch.object(self.controller, 'association', return_value=(run, job)):
                self.assertEqual('pending', self.controller.observe_private()[0])
                self.state.value['private']['cancelRequestedUtc'] = (datetime.now(timezone.utc)-timedelta(seconds=121)).isoformat()
                with self.assertRaisesRegex(coordinator.InvalidEvidence, 'transition-unresolved'):
                    self.controller.observe_private()

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

    def test_merge_verifier_accepts_bound_early_whpx_but_rejects_mutable_ledger(self):
        pp, hp = {'runId': 13, 'receiptDigest': 'e'*64}, {'runId': 12, 'status': 'in_progress'}
        proof = {'candidate': self.state.value['candidate'], 'policySha256': self.state.value['policySha256'],
                 'private': {'state': 'pass', 'proof': pp}, 'hosted': {'state': 'pending', 'proof': hp}}
        body = 'bound proof\n\n```json\n' + coordinator.canonical(proof).decode() + '\n```'
        ledger = {'commentId': 91, 'url': 'https://example.invalid/proof', 'bodySha256': coordinator.digest(body.encode())}
        self.state.value.update(lastOutcome='accepted-whpx', lastProofKey=coordinator.digest(coordinator.canonical(proof)),
                                lastLedger=ledger)
        self.state.value['status-owned'] = {'id': 92}
        comment = {'user': {'login': 'techrote'}, 'html_url': ledger['url'], 'body': body}
        status = {'id': 92, 'context': self.policy['statusContext'], 'creator': {'login': 'techrote'}, 'state': 'success',
                  'target_url': ledger['url'], 'description': 'accepted-whpx proof:' + ledger['bodySha256']}
        class API:
            def request(inner, method, endpoint):
                return (200, comment) if 'issues/comments' in endpoint else (200, [status])
        self.controller.api = API()
        with patch.object(self.controller, 'source'), patch.object(self.controller, 'observe_hosted', return_value=('pending', hp)), \
             patch.object(self.controller, 'observe_private', return_value=('pass', pp)):
            self.assertNotIn('finalOutcome', self.state.value)
            self.assertEqual(0, self.controller.verify_for_merge())
            comment['body'] += '\nchanged'
            with self.assertRaisesRegex(coordinator.InvalidEvidence, 'ledger-changed'):
                self.controller.verify_for_merge()


if __name__ == '__main__':
    unittest.main()
