import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1] / "poc/windows-whpx"
sys.path.insert(0, str(SOURCE))
try:
    import gate_runtime as runtime
finally:
    sys.path.pop(0)


class FakeAPI:
    def __init__(self, replies, state=None):
        self.replies = iter(replies)
        self.calls = []
        self.state = state

    def request(self, method, endpoint, body=None):
        self.calls.append((method, endpoint, body))
        if self.state and method == "POST":
            # Every actual write must already have a durable intent on disk.
            saved = json.loads(self.state.path.read_text())
            assert any(isinstance(v, dict) and (v.get("writeState") == "intent" or "cancelIntent" in v)
                       for v in saved.values())
        reply = next(self.replies)
        if isinstance(reply, Exception):
            raise reply
        return reply


class RuntimeTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="runloc-gate-test-")
        self.addCleanup(self.directory.cleanup)
        path = Path(self.directory.name) / "state.json"
        path.write_text(json.dumps({"comparisonId": "a"*32, "candidate": {"commit": "b"*40}}))
        self.state = runtime.State(path)
        self.arguments = dict(key="hosted", workflow_path="hosted.yml", workflow_commit="c"*40,
                              workflow_ref="tag", comparison="a"*32, title="gate " + "a"*32,
                              inputs={"comparison_id": "a"*32})

    def run_record(self, identifier=12):
        return {"id": identifier, "display_title": self.arguments["title"], "head_sha": "c"*40,
                "event": "workflow_dispatch", "run_attempt": 1, "actor": {"login": "techrote"}}

    def test_dispatch_persists_before_post_and_never_repeats_confirmed_write(self):
        api = FakeAPI([(200, {"workflow_run_id": 12})], self.state)
        self.assertEqual(12, runtime.dispatch_once(self.state, api, **self.arguments))
        self.assertEqual(12, runtime.dispatch_once(runtime.State(self.state.path), api, **self.arguments))
        self.assertEqual(1, len(api.calls))

    def test_lost_post_reconciles_without_second_post(self):
        api = FakeAPI([runtime.UnknownWrite(), (200, {"workflow_runs": [self.run_record()]})], self.state)
        self.assertEqual(12, runtime.dispatch_once(self.state, api, **self.arguments))
        self.assertEqual(["POST", "GET"], [call[0] for call in api.calls])

    def test_unknown_dispatch_waits_and_restart_does_not_replay(self):
        api = FakeAPI([runtime.UnknownWrite(), (200, {"workflow_runs": []})], self.state)
        with self.assertRaises(runtime.UnknownWrite): runtime.dispatch_once(self.state, api, **self.arguments)
        later = FakeAPI([(200, {"workflow_runs": [self.run_record()]})])
        self.assertEqual(12, runtime.dispatch_once(runtime.State(self.state.path), later, **self.arguments))
        self.assertEqual(["GET"], [call[0] for call in later.calls])

    def test_duplicate_runs_and_changed_intents_fail_closed(self):
        api = FakeAPI([runtime.UnknownWrite(), (200, {"workflow_runs": [self.run_record(), self.run_record(13)]})])
        with self.assertRaises(runtime.InvalidEvidence): runtime.dispatch_once(self.state, api, **self.arguments)
        with self.assertRaises(runtime.InvalidEvidence):
            runtime.dispatch_once(self.state, FakeAPI([]), **(self.arguments | {"workflow_commit": "d"*40}))

    def test_cancellation_only_exact_private_never_hosted(self):
        self.state.value.update(hosted={"runId": 12}, private={"runId": 13}); self.state.save()
        for wrong in (12, 99, 0):
            api = FakeAPI([])
            with self.assertRaises(runtime.InvalidEvidence): runtime.cancel_private_once(self.state, api, wrong)
            self.assertFalse(api.calls)
        api = FakeAPI([(202, None)], self.state)
        runtime.cancel_private_once(self.state, api, 13)
        self.assertEqual("repos/techrote/ezvm/actions/runs/13/cancel", api.calls[0][1])

    def test_lost_cancel_observes_instead_of_replaying(self):
        self.state.value.update(hosted={"runId": 12}, private={"runId": 13}); self.state.save()
        api = FakeAPI([runtime.UnknownWrite(), (200, {"status": "in_progress"})], self.state)
        with self.assertRaises(runtime.UnknownWrite): runtime.cancel_private_once(self.state, api, 13)
        later = FakeAPI([(200, {"status": "completed"})])
        runtime.cancel_private_once(runtime.State(self.state.path), later, 13)
        self.assertEqual(["GET"], [c[0] for c in later.calls])

    def test_wrong_actor_or_attempt_is_not_dispatch_reconciliation(self):
        wrong = self.run_record(); wrong["run_attempt"] = 2
        api = FakeAPI([runtime.UnknownWrite(), (200, {"workflow_runs": [wrong]})])
        with self.assertRaises(runtime.UnknownWrite): runtime.dispatch_once(self.state, api, **self.arguments)

    def test_ledger_lost_post_reconciles_exact_author_and_body(self):
        evidence = {'candidate': self.state.value['candidate'], 'outcome': 'pending'}
        body = f"CI-POC-003 proof {'a'*32} {runtime.digest(runtime.canonical(evidence))}\n\n```json\n{runtime.canonical(evidence).decode()}\n```"
        comment = {'id': 91, 'html_url': 'https://github.com/techrote/runloc/issues/23#issuecomment-91',
                   'user': {'login': 'techrote'}, 'body': body}
        api = FakeAPI([runtime.UnknownWrite(), (200, [comment])], self.state)
        ledger = runtime.create_ledger_once(self.state, api, evidence)
        self.assertEqual(91, ledger['commentId'])
        self.assertEqual(runtime.digest(body.encode()), ledger['bodySha256'])
        self.assertEqual(['POST', 'GET'], [c[0] for c in api.calls])
        self.assertEqual(ledger, runtime.create_ledger_once(runtime.State(self.state.path), FakeAPI([]), evidence))

    def test_status_lost_post_refuses_wrong_author_and_never_reposts(self):
        ledger = {'url': 'https://example.invalid/proof', 'bodySha256': 'c'*64}
        api = FakeAPI([runtime.UnknownWrite(), (200, [])], self.state)
        with self.assertRaises(runtime.UnknownWrite):
            runtime.publish_status_once(self.state, api, outcome='accepted-whpx', ledger=ledger)
        saved = next(v for k,v in self.state.value.items() if k.startswith('status-'))
        wrong = saved['body'] | {'id': 33, 'creator': {'login': 'untrusted'}}
        api = FakeAPI([(200, [wrong])])
        with self.assertRaises(runtime.UnknownWrite):
            runtime.publish_status_once(runtime.State(self.state.path), api, outcome='accepted-whpx', ledger=ledger)
        self.assertEqual(['GET'], [c[0] for c in api.calls])
        right = wrong | {'creator': {'login': 'techrote'}}
        api = FakeAPI([(200, [right])])
        runtime.publish_status_once(runtime.State(self.state.path), api, outcome='accepted-whpx', ledger=ledger)
        self.assertEqual(['GET'], [c[0] for c in api.calls])


if __name__ == "__main__":
    unittest.main()
