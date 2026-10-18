"""Opt-in host coordinator. Hosted starts first; unknown evidence never becomes PASS."""
from __future__ import annotations

import argparse
import base64
from contextlib import contextmanager
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import zipfile
import uuid

from gate_runtime import GitHub, State, UnknownWrite, create_ledger_once, dispatch_once, publish_status_once
from qualification_gate import (InvalidEvidence, artifact_files, canonical, decide, digest, json_bytes, require,
                                utc, validate_association, validate_hosted, validate_private)

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = Path(__file__).resolve().parent


def now():
    return datetime.now(timezone.utc).isoformat()


def load(path):
    return json_bytes(Path(path).read_bytes())


def snapshot(path):
    # The accepted 002 writer publishes CreateNew + FileShare.Read before flushing.
    # A torn live read is an unavailable observation, never a qualification verdict.
    for _ in range(5):
        try:
            return load(path)
        except (OSError, ValueError, UnicodeError):
            time.sleep(0.1)
    raise UnknownWrite("local-snapshot-unavailable")


@contextmanager
def exclusive(path):
    import msvcrt
    with Path(path).open("a+b") as lock:
        lock.seek(0); lock.write(b"0"); lock.flush(); lock.seek(0)
        msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
        try:
            yield
        finally:
            lock.seek(0); msvcrt.locking(lock.fileno(), msvcrt.LK_UNLCK, 1)


def run_powershell(script, arguments):
    executable = Path(os.environ["SystemRoot"]) / "System32/WindowsPowerShell/v1.0/powershell.exe"
    result = subprocess.run([str(executable), "-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
                             "-File", str(script), *map(str, arguments)], stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, timeout=60, check=False)
    require(result.returncode == 0 and len(result.stdout) <= 1024*1024, "operator-child-failed")
    return result.stdout.decode("utf-8-sig").strip()


class Coordinator:
    def __init__(self, state, api=None):
        self.state = state
        self.api = api or GitHub()
        self.policy = state.value["policy"]
        self.folder = state.path.parent

    def source(self):
        approved = load(SCRIPT / "gate-policy.json")
        require(canonical(approved) == canonical(self.policy) and digest(canonical(approved)) == self.state.value["policySha256"], "state-policy-not-committed")
        require(self.state.value["selection"] in {"available", "hosted-only", "loss-before-harness"}, "unapproved-selection")
        require(approved["schemaVersion"] == 1 and approved["profile"] == {"cpus": 6, "overallTimeoutDisabled": True}
                and approved["privateQueueSeconds"] == 600 and approved["pollSeconds"] == 30
                and approved["publicationWallSeconds"] == 28800 and approved["statusContext"] == "EzVM qualification / source-bound", "unapproved-policy-profile")
        identity = json_bytes(run_powershell(SCRIPT / "Get-GateSource.ps1",
                             ["-ExpectedCommit", self.state.value["gateController"]["commit"]]).encode())
        require(canonical(identity) == canonical(self.state.value["gateController"]), "gate-source-identity-changed")
        return identity

    def definition(self, lane):
        pin = self.policy[lane]
        status, tag = self.api.request("GET", "repos/techrote/ezvm/git/ref/tags/" + pin["workflowRef"])
        require(status == 200 and tag["object"]["type"] == "commit" and tag["object"]["sha"] == pin["workflowCommit"], "workflow-tag-moved")
        status, response = self.api.request("GET", f"repos/techrote/ezvm/contents/{pin['workflowPath']}?ref={pin['workflowCommit']}")
        require(status == 200 and response["encoding"] == "base64", "workflow-definition-unavailable")
        content = base64.b64decode(response["content"]).decode("utf-8").replace("\r\n", "\n").encode()
        require(digest(content) == pin["sha256Lf"], "unapproved-workflow-definition")

    def start_hosted(self):
        self.definition("hosted")
        comparison = self.state.value["comparisonId"]
        pin = self.policy["hosted"]
        run_id = dispatch_once(self.state, self.api, key="hosted", workflow_path=pin["workflowPath"].rsplit("/", 1)[-1],
                             workflow_commit=pin["workflowCommit"], workflow_ref=pin["workflowRef"], comparison=comparison,
                             title="CI-PoC003 hosted " + comparison, inputs={"comparison_id": comparison})
        return run_id

    def start_private(self):
        value = self.state.value
        require(value.get("hosted", {}).get("runId", 0) > 0, "hosted-must-start-first")
        if "private" in value:
            return  # Never replay local startup on resume, including uncertain startup.
        if value["selection"] == "hosted-only":
            value["private"] = {"outcome": "hosted-only", "reason": "explicit-hosted-only-rollback"}
            self.state.save()
            return
        latch = Path(value["backingRoot"]) / "ci-poc-003-private-quarantine.json"
        if latch.exists():
            value["private"] = {"outcome": "security", "reason": "persistent-private-quarantine"}
            self.state.save()
            return
        self.definition("private")
        capacity = Path(value["backingRoot"]) / "runner-capacity.lock"
        try:
            with capacity.open("r+b"):
                pass
        except OSError as error:
            value["private"] = {"outcome": "busy" if getattr(error, "winerror", None) in (32, 33) else "unknown",
                                "reason": "capacity-lock-unavailable"}
            self.state.save()
            return
        value["private"] = {"outcome": "pending", "startIntentUtc": now(), "startupAttempted": True}
        self.state.save()
        text = run_powershell(Path(value["privateControllerRoot"]) / "poc/windows-whpx/Open-RunnerConsole.ps1", [
            "-Mode", "Start", "-BackingRoot", value["backingRoot"], "-ExpectedControllerCommit",
            self.policy["private"]["hostController"], "-WorkflowRef", self.policy["private"]["workflowRef"],
            "-QualificationMode", "qualification"])
        lines = [line.removeprefix("RUNLOC_CONSOLE_STATE=") for line in text.splitlines() if line.startswith("RUNLOC_CONSOLE_STATE=")]
        require(len(lines) == 1, "private-console-start-unknown-no-replay")
        console = Path(lines[0]).resolve()
        require(console.parent == Path(value["backingRoot"]).resolve() and console.name.startswith("console-"), "console-path-binding")
        value["private"]["console"] = str(console)
        self.state.save()

    def association(self, lane, run_id, comparison):
        status, run = self.api.request("GET", f"repos/techrote/ezvm/actions/runs/{run_id}")
        require(status == 200, "run-state-unavailable")
        status, jobs = self.api.request("GET", f"repos/techrote/ezvm/actions/runs/{run_id}/jobs?per_page=100")
        require(status == 200 and jobs["total_count"] == len(jobs["jobs"]) and len(jobs["jobs"]) <= 1, "job-association-count")
        job = jobs["jobs"][0] if jobs["jobs"] else None
        pin = self.policy[lane]
        require(run["head_sha"] == pin["workflowCommit"] and run["path"].split("@", 1)[0] == pin["workflowPath"]
                and run["display_title"] == ("CI-PoC002 " if lane == "private" else "CI-PoC003 hosted ") + comparison
                and run["event"] == "workflow_dispatch" and run["run_attempt"] == 1 and run["actor"]["login"] == "techrote", "run-association-binding")
        return run, job

    def artifacts(self, lane, run_id, comparison):
        status, response = self.api.request("GET", f"repos/techrote/ezvm/actions/runs/{run_id}/artifacts?per_page=100")
        require(status == 200 and response["total_count"] <= 100, "artifact-inventory")
        name = ("ci-poc-002-" if lane == "private" else "ci-poc-003-hosted-") + comparison
        matches = [a for a in response["artifacts"] if a["name"] == name and not a["expired"]]
        require(len(matches) == 1, "artifact-association-count")
        artifact = matches[0]
        path = self.folder / f"{lane}-{artifact['id']}.zip"
        if not path.exists():
            status, content = self.api.request("GET", f"repos/techrote/ezvm/actions/artifacts/{artifact['id']}/zip", binary=True)
            require(status == 200 and digest(content) == artifact["digest"].removeprefix("sha256:"), "artifact-transport-digest")
            temporary = path.with_name(path.name + ".new-" + uuid.uuid4().hex)
            with temporary.open("xb") as stream:
                stream.write(content)
                stream.flush()
                os.fsync(stream.fileno())
            os.replace(temporary, path)
        documents = artifact_files(path.read_bytes(), artifact["digest"])
        return documents, {key: artifact[key] for key in ("id", "name", "digest", "size_in_bytes")}

    def observe_hosted(self):
        value = self.state.value
        run_id = value["hosted"]["runId"]
        run, job = self.association("hosted", run_id, value["comparisonId"])
        if job is None:
            require(run["status"] != "completed", "completed-run-missing-job")
            return "pending", {"runId": run_id, "status": "await-job-materialization"}
        if job["status"] != "completed":
            return "pending", {"runId": run_id, "jobId": job["id"], "status": job["status"]}
        if job["conclusion"] != "success":
            return "unknown", {"runId": run_id, "jobId": job["id"], "conclusion": job["conclusion"], "classification": "terminal-hosted-failure-not-infrastructure"}
        pin = self.policy["hosted"]
        validate_association(run, job, workflow_commit=pin["workflowCommit"], workflow_path=pin["workflowPath"],
                             title="CI-PoC003 hosted " + value["comparisonId"], candidate=value["candidate"]["commit"], tree=value["candidate"]["tree"])
        documents, artifact = self.artifacts("hosted", run_id, value["comparisonId"])
        receipt = documents["hosted-receipt.json"]
        validate_hosted(receipt, candidate=value["candidate"]["commit"], tree=value["candidate"]["tree"], controller=pin["controller"],
                        comparison=value["comparisonId"], run_id=run_id, workflow_commit=pin["workflowCommit"], created_utc=value["createdUtc"])
        return "pass", {"runId": run_id, "jobId": job["id"], "runnerId": job["runner_id"], "artifact": artifact,
                        "receiptDigest": documents["hosted-receipt-digest.json"]["sha256"], "endedUtc": receipt["endedUtc"], "elapsedSeconds": receipt["elapsedSeconds"]}

    def observe_private(self):
        value = self.state.value
        private = value["private"]
        if private["outcome"] != "pending":
            return private["outcome"], private.get("proof", {"reason": private["reason"]})
        if "console" not in private:
            return "unknown", {"reason": "private-start-unconfirmed-no-replay"}
        console = Path(private["console"])
        stdout = console / "controller.stdout.log"
        lines = stdout.read_text(encoding="utf-8-sig").splitlines() if stdout.exists() else []
        roots = [Path(line.removeprefix("RUNLOC_RUNNER_LEASE=")).resolve() for line in lines if line.startswith("RUNLOC_RUNNER_LEASE=")]
        if not roots:
            if (datetime.now(timezone.utc) - utc(private["startIntentUtc"])).total_seconds() > 90:
                return "unknown", {"reason": "private-start-unconfirmed-no-replay"}
            return "pending", {"reason": "private-starting"}
        require(len(roots) == 1 and roots[0].parent == Path(value["backingRoot"]).resolve(), "private-lease-binding")
        root = roots[0]
        owner = snapshot(root / "lease.json")
        require(re.fullmatch("[a-f0-9]{32}", owner["leaseId"]) and owner["root"] == str(root) and root.name == "runloc-whpx-" + owner["leaseId"] and owner["controllerCommit"] == self.policy["private"]["hostController"]
                and owner["candidateCommit"] == value["candidate"]["commit"] and utc(owner["createdUtc"]) >= utc(value["createdUtc"]), "private-owner-binding")
        events = [snapshot(path) for path in sorted(root.glob("event-*.json"))]
        dispatched = [event for event in events if event["kind"] == "dispatched"]
        if dispatched:
            require(len(dispatched) == 1, "private-duplicate-dispatch")
            private["runId"] = dispatched[0]["data"]["runId"]
            self.state.save()
        if value["selection"] == "loss-before-harness" and dispatched and not private.get("stopIntentUtc"):
            # Real opt-in fault control. Only the exact owned supervisor observes this file.
            private["stopIntentUtc"] = now()
            self.state.save()
            with (root / "stop.request").open("x", encoding="utf-8") as stream:
                json.dump({"leaseId": owner["leaseId"], "requestedUtc": now()}, stream)
        finals = [event for event in events if event["kind"] == "final"]
        if not finals:
            if (console / "controller-started.json").exists():
                snapshot(console / "controller-started.json")
                alive = json_bytes(run_powershell(SCRIPT / "Get-GateControllerState.ps1", ["-ConsoleRoot", console]).encode())
                if alive["alive"] is False:
                    if any(snapshot(path)["kind"] == "final" for path in root.glob("event-*.json")):
                        raise UnknownWrite("private-final-arrived-during-liveness-check")
                    return "unknown", {"leaseId": owner["leaseId"], "runId": private.get("runId"),
                                       "reason": "private-controller-disappeared-cleanup-unconfirmed"}
            return "pending", {"leaseId": owner["leaseId"], "runId": private.get("runId"), "lastEvent": events[-1]["kind"] if events else None}
        require(len(finals) == 1, "private-final-count")
        final = finals[0]["data"]
        ended = console / "controller-ended.json"
        if not ended.exists():
            return "pending", {"reason": "await-actual-controller-exit"}
        status, _ = self.api.request("GET", f"repos/techrote/ezvm/actions/runners/{final['runnerId']}")
        require(status == 404 and final["registrationAbsent"] is True and final["activeProcesses"] == 0
                and final["fixtureRemoved"] is True and final["controllerUnchanged"] is True
                and final["reusableBackingPreserved"] is True and final["unrelatedSentinelSurvived"] is True,
                "private-cleanup-unresolved")
        if final["passed"] is not True:
            if final["reason"] == "no-job-deadline":
                return "queue-expired", {"leaseId": owner["leaseId"], "final": final, "controllerExit": snapshot(ended)}
            if final["reason"] == "owner-cancelled" and private.get("stopIntentUtc") and final["runId"]:
                run, job = self.association("private", final["runId"], owner["leaseId"])
                require(job is not None, "private-job-not-observed")
                scenario = [step for step in job.get("steps", []) if step["name"] == "Exact preflight and full original six-CPU WHPX qualification"]
                require(job["conclusion"] == "cancelled" and len(scenario) == 1
                        and not any(s.get("conclusion") == "failure" for s in job.get("steps", []))
                        and scenario[0].get("conclusion") == "skipped", "fault-control-reached-harness-or-assertion")
                return "cancelled-before-harness", {"leaseId": owner["leaseId"], "runId": run["id"], "jobId": job["id"], "final": final, "controllerExit": snapshot(ended)}
            return "unknown", {"leaseId": owner["leaseId"], "final": final, "controllerExit": snapshot(ended)}
        run, job = self.association("private", final["runId"], owner["leaseId"])
        require(job is not None, "private-job-not-observed")
        require(job["runner_id"] == final["runnerId"] and job["runner_name"] == "runloc-" + owner["leaseId"], "private-runner-binding")
        pin = self.policy["private"]
        validate_association(run, job, workflow_commit=pin["workflowCommit"], workflow_path=pin["workflowPath"], title="CI-PoC002 " + owner["leaseId"],
                             candidate=value["candidate"]["commit"], tree=value["candidate"]["tree"])
        documents, artifact = self.artifacts("private", run["id"], owner["leaseId"])
        receipts = [(name, doc) for name, doc in documents.items() if name.endswith("/receipt.json") and doc["preflightOnly"] is False]
        require(len(receipts) == 1, "full-private-receipt-count")
        name, receipt = receipts[0]
        outer = name.split("/")[0]
        supervisor = documents[outer + "/supervisor-receipt.json"]
        intent = snapshot(root / "runner-intent.json")
        host = {"comparisonId": owner["leaseId"], "runId": run["id"], "jobId": job["id"], "runnerId": final["runnerId"],
                "events": events, "hostController": intent["source"], "controllerExit": snapshot(ended)}
        validate_private(host, documents["actions-job.json"], receipt, supervisor, candidate=value["candidate"]["commit"], tree=value["candidate"]["tree"],
                         controller=pin["jobController"], host_controller=pin["hostController"], comparison=owner["leaseId"], run_id=run["id"],
                         job_id=job["id"], runner_id=final["runnerId"], created_utc=value["createdUtc"],
                         receipt_sha256=documents[name.removesuffix("receipt.json") + "receipt-digest.json"]["sha256"])
        proof = {"leaseId": owner["leaseId"], "runId": run["id"], "jobId": job["id"], "runnerId": final["runnerId"], "artifact": artifact,
                 "receiptDigest": documents[name.removesuffix("receipt.json") + "receipt-digest.json"]["sha256"],
                 "host": host, "elapsedSeconds": final["elapsedSeconds"], "registrationHttpStatus": status}
        return "pass", proof

    def publish(self, private_state, private_proof, hosted_state, hosted_proof):
        # All comparisons on this reusable host share the candidate/context lock.
        with exclusive(Path(self.state.value["backingRoot"]) / "gate-publication.lock"):
            return self.publish_locked(private_state, private_proof, hosted_state, hosted_proof)

    def publish_locked(self, private_state, private_proof, hosted_state, hosted_proof):
        value = self.state.value
        latch = Path(value["backingRoot"]) / "ci-poc-003-private-quarantine.json"
        outcome = decide(private_state, hosted_state, quarantined=latch.exists())
        if outcome == "failure" and not latch.exists():
            with latch.open("xb") as stream:
                stream.write(canonical({"schemaVersion": 1, "candidate": value["candidate"], "comparisonId": value["comparisonId"],
                                        "private": private_state, "hosted": hosted_state, "utc": now(), "resetRequires": "explicit-reviewed-reset"}))
                stream.flush()
                os.fsync(stream.fileno())
        evidence = {"schemaVersion": 1, "issue": "CI-POC-003", "comparisonId": value["comparisonId"], "candidate": value["candidate"],
                    "gateController": value["gateController"], "policySha256": value["policySha256"], "outcome": outcome,
                    "private": {"state": private_state, "proof": private_proof}, "hosted": {"state": hosted_state, "proof": hosted_proof},
                    "createdUtc": value["createdUtc"], "policy": self.policy}
        proof_key = digest(canonical(evidence))
        if value.get("lastProofKey") == proof_key:
            return outcome
        self.source()  # Revalidate coordinator bytes before every authoritative publication.
        ledger = create_ledger_once(self.state, self.api, evidence)
        publish_status_once(self.state, self.api, outcome=outcome, ledger=ledger)
        value.update(lastProofKey=proof_key, lastLedger=ledger, lastOutcome=outcome, lastPublishedUtc=now())
        if outcome.startswith("accepted-") and "firstAcceptedUtc" not in value:
            value["firstAcceptedUtc"] = now()
        self.state.save()
        print(f"{now()} GATE {outcome} private={private_state} hosted={hosted_state} ledger={ledger['url']}", flush=True)
        return outcome

    def verify_for_merge(self):
        """Refetch provenance and mutable ledger/status; check names alone grant nothing."""
        self.source()
        value = self.state.value
        require(value.get("lastOutcome", "").startswith("accepted-"), "comparison-not-accepted")
        hosted, hp = self.observe_hosted()
        private, pp = self.observe_private()
        latch = Path(value["backingRoot"]) / "ci-poc-003-private-quarantine.json"
        require(decide(private, hosted, quarantined=latch.exists()) == value["lastOutcome"], "acceptance-no-longer-valid")
        ledger = value["lastLedger"]
        status, comment = self.api.request("GET", f"repos/techrote/runloc/issues/comments/{ledger['commentId']}")
        require(status == 200 and comment["user"]["login"] == "techrote" and comment["html_url"] == ledger["url"]
                and digest(comment["body"].encode()) == ledger["bodySha256"], "ledger-changed")
        serialized = comment["body"].split("```json\n", 1)[1].split("\n```", 1)[0].encode()
        proof = json_bytes(serialized)
        require(digest(canonical(proof)) == value["lastProofKey"] and proof["candidate"] == value["candidate"]
                and proof["policySha256"] == value["policySha256"] and proof["private"] == {"state": private, "proof": pp}
                and proof["hosted"]["state"] == hosted and proof["hosted"]["proof"]["runId"] == hp["runId"], "ledger-provenance-changed")
        if hosted != "pending":
            require(proof["hosted"]["proof"] == hp, "hosted-proof-changed")
        status, statuses = self.api.request("GET", f"repos/techrote/ezvm/commits/{value['candidate']['commit']}/statuses?per_page=100")
        require(status == 200, "statuses-unavailable")
        context = [entry for entry in statuses if entry["context"] == self.policy["statusContext"]]
        require(context and context[0]["creator"]["login"] == "techrote" and context[0]["state"] == "success"
                and context[0]["target_url"] == ledger["url"]
                and context[0]["description"] == f"{value['lastOutcome']} proof:{ledger['bodySha256']}", "latest-status-not-bound")
        require(any(isinstance(entry, dict) and entry.get("id") == context[0]["id"]
                    and key.startswith("status-") for key, entry in value.items()), "unowned-status-id")
        print(f"{now()} VERIFIED_FOR_MERGE candidate={value['candidate']['commit']} ledger={ledger['url']}", flush=True)
        return 0

    def run(self):
        value = self.state.value
        require(self.policy["executionApproved"] is True, "gate-execution-not-approved")
        require(value["candidate"] == self.policy["candidate"], "gate-candidate-not-approved")
        self.source()
        errors = 0
        while True:
            try:
                self.start_hosted()  # Resume reconciles uncertain writes without replaying them.
                self.start_private()  # Must follow a confirmed independent hosted run.
                hosted_state, hosted_proof = self.observe_hosted()
                private_state, private_proof = self.observe_private()
                outcome = self.publish(private_state, private_proof, hosted_state, hosted_proof)
                errors = 0
                if hosted_state != "pending" and private_state != "pending":
                    value.update(completedUtc=now(), finalOutcome=outcome)
                    self.state.save()
                    return 0 if outcome.startswith("accepted-") else 1
            except (InvalidEvidence, KeyError, ValueError, TypeError, IndexError, AttributeError, zipfile.BadZipFile) as error:
                # Malformed/unknown evidence is a blocked gate, never an infrastructure pass.
                value["evidenceError"] = type(error).__name__
                self.state.save()
                self.publish("unknown", {"reason": "evidence-validation-failed"}, "pending", {})
                return 1
            except (UnknownWrite, subprocess.TimeoutExpired, OSError):
                errors += 1
                value["apiUnavailableObservations"] = errors
                self.state.save()
                print(f"{now()} API_UNAVAILABLE observation={errors}; no outcome inferred", flush=True)
            if (datetime.now(timezone.utc) - utc(value["createdUtc"])).total_seconds() > self.policy["publicationWallSeconds"]:
                self.publish("unknown", {"reason": "publication-wall-reached"}, "pending", {})
                return 1
            print(f"{now()} OBSERVER_HEARTBEAT hostedRun={value.get('hosted', {}).get('runId')} privateRun={value.get('private', {}).get('runId')}", flush=True)
            time.sleep(2 if value["selection"] == "loss-before-harness" and not value.get("private", {}).get("stopIntentUtc") else self.policy["pollSeconds"])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--state", required=True)
    parser.add_argument("--seal-initial-state", action="store_true")
    parser.add_argument("--verify-for-merge", action="store_true")
    args = parser.parse_args()
    require(sys.platform == "win32", "native-windows-operator-required")
    state = State(args.state)
    if args.seal_initial_state:
        require(state.value["policySha256"] == "" and "hosted" not in state.value and "private" not in state.value, "state-already-sealed")
        state.value["policySha256"] = digest(canonical(state.value["policy"]))
        Coordinator(state).source()
        state.save()
        return 0
    import msvcrt
    with state.path.with_suffix(".lock").open("a+b") as lock:
        lock.seek(0); lock.write(b"0"); lock.flush(); lock.seek(0)
        msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
        try:
            coordinator = Coordinator(state)
            return coordinator.verify_for_merge() if args.verify_for_merge else coordinator.run()
        finally:
            lock.seek(0); msvcrt.locking(lock.fileno(), msvcrt.LK_UNLCK, 1)


if __name__ == "__main__":
    raise SystemExit(main())
