"""Offline policy/evidence tests; retained receipts are parser fixtures, not new runs."""
import copy
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("qualification_gate", ROOT / "poc/windows-whpx/qualification_gate.py")
gate = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(gate)


class AssertionControlTests(unittest.TestCase):
    def setUp(self):
        self.expected = dict(candidate='a'*40, tree='b'*40, controller='c'*40, controller_tree='d'*40,
            comparison='e'*32, workflow_commit='f'*40, workflow_path='.github/workflows/ezvm-ci-poc-003-hosted.yml',
            created_utc='2026-10-20T00:00:00Z')
        self.run = dict(id=31, repository={'full_name': 'techrote/ezvm'}, event='workflow_dispatch', actor={'login': 'techrote'},
            run_attempt=1, head_sha='f'*40, path=self.expected['workflow_path'], display_title='CI-PoC003 assertion '+'e'*32,
            status='completed', conclusion='failure')
        self.job = dict(run_id=31, status='completed', conclusion='failure', runner_id=4, runner_name='GitHub Actions',
            steps=[dict(status='completed', conclusion='failure', name='Authenticated fixed false guest assertion (expected failure)')])
        self.receipt = dict(schemaVersion=1, negativeControlOnly=True, qualificationPassed=False, passed=False, controlObserved=True,
            control='authenticated-fixed-false-guest-assertion', candidate={'commit': 'a'*40, 'tree': 'b'*40},
            controller={'commit': 'c'*40, 'tree': 'd'*40}, comparisonId='e'*32, workflowCommit='f'*40,
            repository='techrote/ezvm', runId=31, runAttempt=1, runnerEnvironment='github-hosted', runnerName='GitHub Actions',
            requestedAccelerator='tcg', qualificationCpus=6, qualificationMemoryMiB=4096, sourceUnchanged=True, errors=[],
            exitCode=1, guestAssertionExitCode=1, preflightExitCode=0, timedOut=False, cancelled=False, outputFailed=False,
            outputOverflow=False, preflightTimedOut=False, preflightCancelled=False,
            cleanup=dict(childExited=True, activeProcesses=0, forced=False, fixtureRemoved=True),
            elapsedSeconds=30, startedUtc='2026-10-20T00:00:01Z', endedUtc='2026-10-20T00:00:31Z')

    def test_real_failed_control_classification_can_only_block_even_with_green_other_lane(self):
        outcome = gate.validate_assertion_control(self.receipt, self.run, self.job, **self.expected)
        self.assertEqual('assertion', outcome)
        self.assertEqual('failure', gate.decide(outcome, 'pass'))
        self.assertEqual('failure', gate.decide('pass', outcome))

    def test_control_cannot_hide_wrong_exit_partial_cleanup_profile_or_false_success(self):
        changes = {'passed': True, 'negativeControlOnly': False, 'qualificationPassed': True, 'controlObserved': False,
            'sourceUnchanged': False, 'exitCode': 0, 'guestAssertionExitCode': 0, 'preflightExitCode': 1,
            'qualificationCpus': 8, 'requestedAccelerator': 'whpx', 'timedOut': True, 'cancelled': True,
            'outputFailed': True, 'preflightTimedOut': True, 'preflightCancelled': True, 'errors': ['cleanup']}
        for key, value in changes.items():
            with self.subTest(key=key), self.assertRaises(gate.InvalidEvidence):
                gate.validate_assertion_control(self.receipt | {key: value}, self.run, self.job, **self.expected)
        for key, value in {'activeProcesses': 1, 'fixtureRemoved': False, 'forced': True, 'childExited': False}.items():
            with self.subTest(key=key), self.assertRaises(gate.InvalidEvidence):
                gate.validate_assertion_control(self.receipt | {'cleanup': self.receipt['cleanup'] | {key: value}}, self.run, self.job, **self.expected)

    def test_control_requires_actual_failed_job_exact_definition_fresh_source_and_expected_step(self):
        for key, value in {'conclusion': 'success', 'head_sha': '0'*40, 'run_attempt': 2, 'display_title': 'replay'}.items():
            with self.subTest(key=key), self.assertRaises(gate.InvalidEvidence):
                gate.validate_assertion_control(self.receipt, self.run | {key: value}, self.job, **self.expected)
        for key in ('candidate', 'tree', 'controller', 'controller_tree', 'comparison', 'workflow_commit'):
            with self.subTest(key=key), self.assertRaises(gate.InvalidEvidence):
                gate.validate_assertion_control(self.receipt, self.run, self.job, **(self.expected | {key: '0'*len(self.expected[key])}))
        with self.assertRaises(gate.InvalidEvidence):
            gate.validate_assertion_control(self.receipt, self.run, self.job | {'steps': []}, **self.expected)

    def test_control_archive_has_separate_closed_two_file_schema_and_digest(self):
        def archive(extra=False):
            buffer = io.BytesIO()
            raw = gate.canonical(self.receipt)
            with zipfile.ZipFile(buffer, 'w') as zipped:
                zipped.writestr('assertion-control-receipt.json', raw)
                zipped.writestr('assertion-control-receipt-digest.json', gate.canonical(dict(schemaVersion=1,
                    file='assertion-control-receipt.json', sha256=gate.digest(raw))))
                if extra: zipped.writestr('../private.log', 'synthetic-secret')
            return buffer.getvalue()
        raw = archive()
        self.assertEqual(self.receipt, gate.assertion_control_artifact_files(raw, gate.digest(raw))['assertion-control-receipt.json'])
        with self.assertRaises(gate.InvalidEvidence): gate.assertion_control_artifact_files(raw, '0'*64)
        extra = archive(True)
        with self.assertRaises(gate.InvalidEvidence): gate.assertion_control_artifact_files(extra, gate.digest(extra))


class GatePolicyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        folder = ROOT / "docs/fast-track/evidence/ci-poc-002-full"
        cls.host = json.loads((folder.parent / "ci-poc-002-full-host.json").read_text(encoding="utf-8-sig"))
        cls.actions = json.loads((folder / "actions-job.json").read_text(encoding="utf-8-sig"))
        cls.receipt = next(r for p in folder.rglob("receipt.json")
                           if (r := json.loads(p.read_text(encoding="utf-8-sig")))["outcome"] == "pass")
        cls.supervisor = next(r for p in folder.rglob("supervisor-receipt.json")
                              if (r := json.loads(p.read_text(encoding="utf-8-sig")))["outcome"] == "pass")
        cls.expected = dict(candidate=cls.receipt["candidate"]["commit"], tree=cls.receipt["candidate"]["tree"],
                            controller=cls.receipt["controller"]["commit"], host_controller=cls.host["hostController"]["commit"],
                            comparison=cls.host["comparisonId"], run_id=cls.host["runId"], job_id=cls.host["jobId"],
                            runner_id=cls.host["runnerId"], created_utc="2026-10-18T15:49:00Z",
                            receipt_sha256=cls.supervisor["inner"]["receiptSha256"])

    def test_known_complete_parser_fixture(self):
        self.assertEqual("pass", gate.validate_private(self.host, self.actions, self.receipt, self.supervisor, **self.expected))

    def test_source_and_attempt_replay_are_rejected(self):
        for field, value in (("candidate", "b"*40), ("tree", "c"*40), ("comparison", "a"*32),
                             ("run_id", 42), ("job_id", 42), ("runner_id", 42), ("controller", "b"*40),
                             ("created_utc", "2026-10-19T00:00:00Z")):
            with self.subTest(field=field), self.assertRaises(gate.InvalidEvidence):
                expected = self.expected | {field: value}
                gate.validate_private(self.host, self.actions, self.receipt, self.supervisor, **expected)

    def test_false_pass_and_cleanup_mutations(self):
        for path, value in (("exitCode", 1), ("childExitCode", 1), ("sourceUnchanged", False), ("timedOut", True),
                            ("outputFailed", True), ("controllerFailure", True), ("preflightOnly", True)):
            bad = copy.deepcopy(self.receipt); bad[path] = value
            with self.subTest(field=path), self.assertRaises(gate.InvalidEvidence):
                gate.validate_private(self.host, self.actions, bad, self.supervisor, **self.expected)
        for field, value in (("activeProcesses", 1), ("fixtureRemoved", False), ("forced", True)):
            bad = copy.deepcopy(self.receipt); bad["cleanup"][field] = value
            with self.subTest(field=field), self.assertRaises(gate.InvalidEvidence):
                gate.validate_private(self.host, self.actions, bad, self.supervisor, **self.expected)

    def test_ordered_complete_evidence_negative_controls(self):
        original = self.receipt["events"]
        variants = []
        variants.append([e for e in original if e["kind"] != "boundary"])
        variants.append([e for e in original if e["name"] != "EZVM012_REAL_COMPLETE_END_TO_END"])
        duplicate = copy.deepcopy(original); duplicate.insert(3, copy.deepcopy(original[2])); variants.append(duplicate)
        replay = copy.deepcopy(original)
        for e in replay:
            if e["kind"] == "guest-cpus": e["name"] = "ezvm010-source"
            if e["kind"] == "phase" and e["name"] == "guest_ready": e["value"] = "ezvm010-source"
        variants.append(replay)
        late = copy.deepcopy(original)
        next(e for e in reversed(late) if e["kind"] == "phase" and e["name"] == "guest_ready")["seconds"] = 9000
        variants.append(sorted(late, key=lambda e: e["seconds"]))
        wrong_cpu = copy.deepcopy(original)
        next(e for e in wrong_cpu if e["kind"] == "guest-cpus")["value"] = "8"; variants.append(wrong_cpu)
        for index, events in enumerate(variants):
            with self.subTest(variant=index), self.assertRaises(gate.InvalidEvidence):
                gate.validate_events(events, "whpx")

    def test_preflight_schema_and_digest_chain_fail_closed(self):
        for target, field, value in (("cleanup", "activeProcesses", False), ("preflight", "exitCode", 123),
                                     ("preflight", "forced", 0)):
            bad = copy.deepcopy(self.receipt); bad[target][field] = value
            with self.subTest(field=field), self.assertRaises(gate.InvalidEvidence):
                gate.validate_private(self.host, self.actions, bad, self.supervisor, **self.expected)
        bad = copy.deepcopy(self.receipt); bad['requestedGuestCpus'] = 6.0
        with self.assertRaises(gate.InvalidEvidence): gate.validate_private(self.host, self.actions, bad, self.supervisor, **self.expected)
        bad = copy.deepcopy(self.supervisor); bad['inner']['receiptSha256'] = 'f'*64
        with self.assertRaises(gate.InvalidEvidence): gate.validate_private(self.host, self.actions, self.receipt, bad, **self.expected)

    def test_failure_dominates_all_green_and_infrastructure_states(self):
        private_states = gate.INFRASTRUCTURE | gate.FAILURES | {"pending", "pass", "hosted-only"}
        for private in private_states:
            for hosted in gate.FAILURES | {"pass", "pending"}:
                with self.subTest(private=private, hosted=hosted):
                    result = gate.decide(private, hosted)
                    if private in gate.FAILURES or hosted in gate.FAILURES:
                        self.assertEqual("failure", result)
                    elif private == "pass": self.assertEqual("accepted-whpx", result)
                    elif hosted == "pass" and private != "pending": self.assertEqual("accepted-tcg", result)
                    else: self.assertEqual("pending", result)
        self.assertEqual("failure", gate.decide("pass", "pass", quarantined=True))
        with self.assertRaises(gate.InvalidEvidence): gate.decide("retry-and-ignore", "pass")

    def test_duplicate_json_and_unsafe_or_tampered_artifacts(self):
        with self.assertRaises(gate.InvalidEvidence): gate.json_bytes(b'{"passed":false,"passed":true}')
        for name in ("../receipt.json", "private.log", "root/../receipt.json"):
            stream = io.BytesIO()
            with zipfile.ZipFile(stream, "w") as archive: archive.writestr(name, b'{}')
            value = stream.getvalue()
            with self.subTest(name=name), self.assertRaises(gate.InvalidEvidence):
                gate.artifact_files(value, hashlib.sha256(value).hexdigest())
        with self.assertRaises(gate.InvalidEvidence): gate.artifact_files(b'bad', 'a'*64)


if __name__ == "__main__":
    unittest.main()
