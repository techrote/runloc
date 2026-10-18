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
                            runner_id=cls.host["runnerId"], created_utc="2026-10-18T15:49:00Z")

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

    def test_failure_dominates_all_green_and_infrastructure_states(self):
        private_states = gate.INFRASTRUCTURE | gate.FAILURES | {"pending", "pass", "hosted-only"}
        for private in private_states:
            for hosted in gate.FAILURES | {"pass", "pending"}:
                with self.subTest(private=private, hosted=hosted):
                    result = gate.decide(private, hosted)
                    if private in gate.FAILURES or hosted in gate.FAILURES:
                        self.assertEqual("failure", result)
                    elif private == "pass": self.assertEqual("accepted-whpx", result)
                    elif hosted == "pass": self.assertEqual("accepted-tcg", result)
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
