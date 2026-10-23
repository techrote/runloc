"""Durable GitHub boundary for the manually authorized CI-PoC coordinator."""
from __future__ import annotations

import json
import os
from pathlib import Path
import re
import subprocess
import uuid

from qualification_gate import InvalidEvidence, canonical, digest, json_bytes, require


class UnknownWrite(RuntimeError):
    pass


class GitHub:
    def request(self, method, endpoint, body=None, *, binary=False):
        require(method in {"GET", "POST"}, "unsupported-api-method")
        require(re.match(r"^repos/techrote/(ezvm/(actions/|statuses/|commits/|contents/|git/)|runloc/issues/(23/comments|comments/\d+)(?:[/?]|$))", endpoint), "api-scope")
        arguments = ["gh", "api", "--hostname", "github.com", "--method", method,
                     "-H", "X-GitHub-Api-Version: 2026-03-10", endpoint]
        if not binary:
            arguments.append("--include")
        if body is not None:
            arguments += ["--input", "-"]
        result = subprocess.run(arguments, input=canonical(body) if body is not None else None,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=40, check=False)
        require(len(result.stdout) <= (32*1024*1024 if binary else 8*1024*1024), "api-size-bound")
        if binary:
            require(result.returncode == 0, "artifact-download-unavailable")
            return 200, result.stdout
        # Neither raw stderr nor API payloads become public exception/log text.
        match = re.match(rb"HTTP/[\d.]+ (\d{3})[^\r\n]*\r?\n", result.stdout)
        if not match:
            raise UnknownWrite("github-response-unavailable")
        status = int(match[1])
        parts = re.split(rb"\r?\n\r?\n", result.stdout, maxsplit=1)
        data = json_bytes(parts[1]) if len(parts) == 2 and parts[1].strip() else None
        return status, data


class State:
    def __init__(self, path):
        self.path = Path(path)
        self.value = json_bytes(self.path.read_bytes())

    def save(self):
        temporary = self.path.with_name(self.path.name + ".new-" + uuid.uuid4().hex)
        with temporary.open("xb") as stream:
            stream.write(canonical(self.value))
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, self.path)


def dispatch_once(state, api, *, key, workflow_path, workflow_commit, workflow_ref, comparison, title, inputs):
    """An ambiguous POST is reconciled on restart, never replayed."""
    intent = dict(path=workflow_path, commit=workflow_commit, ref=workflow_ref, comparison=comparison,
                  title=title, inputs=inputs)
    previous = state.value.get(key)
    if key in state.value:
        require(isinstance(previous, dict) and previous.get("intent") == intent
                and previous.get("writeState") in {"intent", "unknown", "confirmed", "reconciled"}, "dispatch-intent-changed-or-malformed")
        if "runId" in previous:
            require(type(previous["runId"]) is int and previous["runId"] > 0
                    and previous["writeState"] in {"confirmed", "reconciled"}, "dispatch-confirmation-invalid")
            return previous["runId"]
        require(previous["writeState"] in {"intent", "unknown"}, "dispatch-confirmation-missing-id")
    else:
        state.value[key] = {"intent": intent, "writeState": "intent"}
        state.save()
        try:
            status, response = api.request("POST", f"repos/techrote/ezvm/actions/workflows/{workflow_path}/dispatches",
                                           {"ref": workflow_ref, "return_run_details": True, "inputs": inputs})
            if status == 200 and type(response.get("workflow_run_id")) is int and response["workflow_run_id"] > 0:
                state.value[key].update(runId=response["workflow_run_id"], writeState="confirmed")
                state.save()
                return response["workflow_run_id"]
        except (UnknownWrite, subprocess.TimeoutExpired, OSError):
            pass
        state.value[key]["writeState"] = "unknown"
        state.save()
    status, runs = api.request("GET", f"repos/techrote/ezvm/actions/workflows/{workflow_path}/runs?event=workflow_dispatch&per_page=100")
    require(status == 200 and len(runs["workflow_runs"]) <= 100, "dispatch-reconciliation-bound")
    matched = [run for run in runs["workflow_runs"] if run["display_title"] == title and run["head_sha"] == workflow_commit
               and run["event"] == "workflow_dispatch" and type(run["run_attempt"]) is int
               and run["run_attempt"] == 1 and run["actor"]["login"] == "techrote"]
    require(len(matched) <= 1, "duplicate-dispatch")
    if not matched:
        raise UnknownWrite("dispatch-not-yet-reconciled-do-not-replay")
    require(type(matched[0].get("id")) is int and matched[0]["id"] > 0, "dispatch-reconciled-run-id-invalid")
    state.value[key].update(runId=matched[0]["id"], writeState="reconciled")
    state.save()
    return matched[0]["id"]


def cancel_private_once(state, api, run_id):
    private = state.value.get("private", {})
    hosted = state.value["hosted"]["runId"]
    require(type(run_id) is int and run_id > 0 and private.get("runId") == run_id and run_id != hosted,
            "cancellation-not-exact-private-run")
    if "cancelIntent" not in private:
        private["cancelIntent"] = {"runId": run_id}
        state.save()
        try:
            status, _ = api.request("POST", f"repos/techrote/ezvm/actions/runs/{run_id}/cancel")
            if status == 202:
                private["cancelConfirmed"] = True
                state.save()
                return
        except (UnknownWrite, subprocess.TimeoutExpired, OSError):
            pass
    status, run = api.request("GET", f"repos/techrote/ezvm/actions/runs/{run_id}")
    require(status == 200, "cancellation-state-unknown")
    if run["status"] != "completed":
        raise UnknownWrite("private-cancellation-pending-no-replay")
    private["cancelConfirmed"] = True
    state.save()


def create_ledger_once(state, api, evidence):
    serialized = canonical(evidence)
    proof_hash = digest(serialized)
    prefix = f"CI-POC-003 proof {state.value['comparisonId']} {proof_hash}"
    body = prefix + "\n\n```json\n" + serialized.decode() + "\n```"
    require(len(body.encode()) <= 60000, "public-ledger-size")
    key = "ledger-" + proof_hash
    if key not in state.value:
        state.value[key] = {"bodySha256": digest(body.encode()), "writeState": "intent"}
        state.save()
        try:
            status, response = api.request("POST", "repos/techrote/runloc/issues/23/comments", {"body": body})
            if status == 201:
                require(response["user"]["login"] == "techrote" and response["body"] == body, "ledger-identity")
                state.value[key].update(commentId=response["id"], url=response["html_url"], writeState="confirmed")
                state.save()
                return state.value[key]
        except (UnknownWrite, subprocess.TimeoutExpired, OSError):
            pass
    if "commentId" not in state.value[key]:
        status, comments = api.request("GET", "repos/techrote/runloc/issues/23/comments?per_page=100")
        require(status == 200 and len(comments) < 100, "ledger-reconciliation-bound")
        matches = [c for c in comments if c["user"]["login"] == "techrote" and c["body"] == body]
        require(len(matches) <= 1, "duplicate-ledger")
        if not matches:
            raise UnknownWrite("ledger-unconfirmed-do-not-replay")
        state.value[key].update(commentId=matches[0]["id"], url=matches[0]["html_url"], writeState="reconciled")
        state.save()
    return state.value[key]


def publish_status_once(state, api, *, outcome, ledger):
    body = {"state": "success" if outcome.startswith("accepted-") else "failure" if outcome == "failure" else "pending",
            "context": "EzVM qualification / source-bound", "target_url": ledger["url"],
            "description": f"{outcome} proof:{ledger['bodySha256']}"}
    key = "status-" + digest(canonical(body))
    endpoint = f"repos/techrote/ezvm/statuses/{state.value['candidate']['commit']}"
    if key not in state.value:
        state.value[key] = {"body": body, "writeState": "intent"}
        state.save()
        try:
            status, response = api.request("POST", endpoint, body)
            if status == 201:
                state.value[key].update(id=response["id"], writeState="confirmed")
                state.save()
                return
        except (UnknownWrite, subprocess.TimeoutExpired, OSError):
            pass
    status, statuses = api.request("GET", f"repos/techrote/ezvm/commits/{state.value['candidate']['commit']}/statuses?per_page=100")
    require(status == 200 and len(statuses) < 100, "status-reconciliation-bound")
    matching = [entry for entry in statuses if entry["creator"]["login"] == "techrote"
                and all(entry[k] == v for k, v in body.items())]
    if not matching:
        raise UnknownWrite("status-unconfirmed-do-not-replay")
    state.value[key].update(id=matching[0]["id"], writeState="reconciled")
    state.save()
