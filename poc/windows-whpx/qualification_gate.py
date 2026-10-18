"""CI-PoC source-bound qualification policy. No credentials or live I/O on import."""
from __future__ import annotations

import hashlib
import io
import json
import math
import re
import zipfile
from collections import Counter
from datetime import datetime

CONTEXT = "EzVM qualification / source-bound"
FUNCTIONAL_MARKERS = (
    "EZVM012_REAL_FRESH_ROOT_DOCTOR", "EZVM012_REAL_BOOTSTRAP_DOCTOR",
    "EZVM010_REAL_TINY_RESET_FRESH_STATEFUL_INDEPENDENCE",
    "EZVM010_REAL_SENSITIVE_BASELINE_RESET_AND_FRESH", "EZVM010_REAL_STANDALONE_EXPORT_IMPORT",
    "EZVM010_REAL_UNSAFE_IMPORT_REFUSAL", "EZVM010_REAL_FAILED_EXPORT_PRESERVES_DATA",
    "EZVM012_REAL_TWO_CONCURRENT_READY_GUESTS",
    "EZVM011_REAL_SCP_ROUNDTRIP_AND_FAILED_DESTINATION_PRESERVATION",
    "EZVM011_REAL_RUNNING_DIAGNOSIS_AND_RUNTIME_TRANSFER_REFUSAL",
    "EZVM012_REAL_STOP_RESTART_PERSISTENCE", "EZVM010_REAL_RUNNING_OPERATIONS_REFUSE",
    "EZVM012_REAL_FRESH_CLONE_PRISTINE_READY", "EZVM010_REAL_RESET_PRISTINE_READY",
    "EZVM010_REAL_STATEFUL_NEW_IDENTITY_AND_CONTENT", "EZVM010_REAL_IMPORTED_NEW_IDENTITY_AND_CONTENT",
    "EZVM012_REAL_RELOCATED_DOCTOR", "EZVM010_REAL_COLD_RELOCATION_READY",
    "EZVM010_REAL_RELATIVE_BACKING_AND_RUNTIME_REGENERATION", "EZVM010_REAL_GRACEFUL_STOP",
    "EZVM011_REAL_COMPLETE_SECURITY_AND_PORTABILITY", "EZVM012_REAL_RELOCATED_DOCTOR_AND_RESTART",
    "EZVM012_REAL_COMPLETE_END_TO_END",
)
INFRASTRUCTURE = frozenset({"absent", "busy", "queue-expired", "cancelled-before-harness",
                            "permission-denied-before-start", "registration-failed-before-job"})
FAILURES = frozenset({"assertion", "unknown", "source", "security", "cleanup"})


class InvalidEvidence(ValueError):
    pass


def require(condition, reason):
    if not condition:
        raise InvalidEvidence(reason)


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode()


def digest(value: bytes):
    return hashlib.sha256(value).hexdigest()


def json_bytes(value: bytes):
    def unique(pairs):
        result = {}
        for key, item in pairs:
            require(key not in result, "duplicate-json-property")
            result[key] = item
        return result
    require(len(value) <= 8 * 1024 * 1024, "json-size-limit")
    return json.loads(value.decode("utf-8-sig"), object_pairs_hook=unique)


def utc(value):
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def artifact_files(archive: bytes, expected_sha256: str):
    require(digest(archive) == expected_sha256.removeprefix("sha256:"), "artifact-archive-digest")
    result = {}
    allowed = {"actions-job.json", "receipt.json", "receipt-digest.json", "supervisor-receipt.json",
               "supervisor-receipt-digest.json", "supervisor-started.json", "telemetry-events.json",
               "hosted-receipt.json", "hosted-receipt-digest.json"}
    with zipfile.ZipFile(io.BytesIO(archive)) as zipped:
        require(len(zipped.infolist()) <= 32, "artifact-entry-count")
        for item in zipped.infolist():
            if item.is_dir():
                continue
            path = item.filename.split("/")
            require(len(path) <= 4 and all(p not in ("", ".", "..") for p in path)
                    and "\\" not in item.filename and ":" not in item.filename,
                    "artifact-path")
            require(path[-1] in allowed and item.filename not in result, "artifact-vocabulary-or-duplicate")
            require(item.file_size <= 8 * 1024 * 1024, "artifact-file-size")
            result[item.filename] = zipped.read(item)
    require(sum(map(len, result.values())) <= 16 * 1024 * 1024, "artifact-total-size")
    for path, content in result.items():
        if path.endswith("-digest.json"):
            record = json_bytes(content)
            base = path.rsplit("/", 1)[0] + "/" if "/" in path else ""
            require(record["file"] in allowed and "/" not in record["file"], "receipt-digest-file")
            require(base + record["file"] in result and digest(result[base + record["file"]]) == record["sha256"],
                    "receipt-digest-mismatch")
    documents = {name: json_bytes(content) for name, content in result.items()}
    for name, document in documents.items():
        filename = name.rsplit("/", 1)[-1]
        base = name.rsplit("/", 1)[0] + "/" if "/" in name else ""
        if filename in {"receipt.json", "supervisor-receipt.json", "hosted-receipt.json"}:
            require(base + filename.removesuffix(".json") + "-digest.json" in documents, "missing-receipt-digest")
        telemetry = document.get("telemetry") if isinstance(document, dict) else None
        if isinstance(telemetry, dict) and telemetry.get("complete") is True:
            require(telemetry.get("publicFile") == "telemetry-events.json" and base + "telemetry-events.json" in result,
                    "missing-complete-telemetry")
            require(digest(result[base + "telemetry-events.json"]) == telemetry["publicSha256"], "telemetry-digest-binding")
    return documents


def validate_association(run, job, *, workflow_commit, workflow_path, title, candidate, tree):
    require(run["repository"]["full_name"] == "techrote/ezvm" and run["event"] == "workflow_dispatch"
            and run["actor"]["login"] == "techrote" and run["run_attempt"] == 1, "untrusted-run")
    require(run["head_sha"] == workflow_commit and run["path"].split("@", 1)[0] == workflow_path
            and run["display_title"] == title, "run-definition-binding")
    require(job["run_id"] == run["id"] and job["status"] == "completed"
            and job["conclusion"] == "success" and job["runner_id"] > 0, "job-not-successful")
    require(re.fullmatch(r"[a-f0-9]{40}", candidate) and re.fullmatch(r"[a-f0-9]{40}", tree), "source-identity-format")


def validate_events(events, accelerator):
    require(isinstance(events, list) and 0 < len(events) <= 10000, "event-count")
    begin = [e for e in events if e.get("kind") == "boundary" and e.get("name") == "STARTED_AT"]
    end = [e for e in events if e.get("kind") == "boundary" and e.get("name") == "COMPLETED_AT"]
    require(len(begin) == len(end) == 1 and begin[0]["seconds"] < end[0]["seconds"], "qualification-boundaries")
    last = -1.0
    for event in events:
        require(all(type(event.get(k)) is str for k in ("kind", "name", "value", "utc")), "event-types")
        seconds = event["seconds"]
        require(type(seconds) in (int, float) and math.isfinite(seconds) and seconds >= last, "event-clock")
        require(utc(event["utc"]).tzinfo is not None, "event-utc")
        last = seconds
        if event["kind"] in {"marker", "accelerator", "guest-cpus"} or (
                event["kind"] == "phase" and event["name"] in {"guest_ready", "guest_start"}):
            require(begin[0]["seconds"] < seconds < end[0]["seconds"], "event-outside-boundaries")
    expected = set(FUNCTIONAL_MARKERS) | ({"EZVM010_WHPX_EXECUTION"} if accelerator == "whpx" else set())
    markers = Counter(e["name"] for e in events if e["kind"] == "marker" and e["value"] == "PASS")
    require(markers == Counter({key: 1 for key in expected}), "completion-markers")
    require(not any(e["kind"] == "failure" for e in events), "harness-failure")
    ready = [e for e in events if e["kind"] == "phase" and e["name"] == "guest_ready"]
    cpus = [e for e in events if e["kind"] == "guest-cpus"]
    require(len(ready) == len(cpus) == 8 and all(e["value"] == "6" for e in cpus), "ready-or-cpu-proof")
    sequence = ["ezvm010-source", "ezvm012-secondary", "ezvm010-source", "ezvm012-fresh", "ezvm010-source",
                "ezvm010-stateful", "ezvm010-imported", "ezvm010-stateful"]
    require([e["value"] for e in ready] == [e["name"] for e in cpus] == sequence, "ready-instance-binding")
    for index, (cpu, response) in enumerate(zip(cpus, ready)):
        require(cpu["seconds"] <= response["seconds"] and (index == 0 or cpu["seconds"] > ready[index-1]["seconds"]),
                "cpu-ready-order")
    require([e["value"] for e in events if e["kind"] == "accelerator"] == [accelerator], "accelerator-evidence")


def validate_private(host, actions, receipt, supervisor, *, candidate, tree, controller, host_controller,
                     comparison, run_id, job_id, runner_id, created_utc):
    require(host["hostController"]["commit"] == host_controller, "host-controller-pin")
    require(host["comparisonId"] == comparison and host["runId"] == run_id
            and host["jobId"] == job_id and host["runnerId"] == runner_id, "host-association")
    final = [e for e in host["events"] if e["kind"] == "final"]
    require(len(final) == 1 and final[0]["leaseId"] == comparison, "host-final-binding")
    end = final[0]["data"]
    require(end["runId"] == run_id and end["runnerId"] == runner_id and end["passed"] is True
            and end["activeProcesses"] == 0 and all(end[k] is True for k in (
                "fixtureRemoved", "registrationAbsent", "reusableBackingPreserved", "unrelatedSentinelSurvived",
                "controllerUnchanged", "workflowCleanupConfirmed")), "host-disposal")
    require(host["controllerExit"]["exitObserved"] is True and type(host["controllerExit"]["exitCode"]) is int
            and host["controllerExit"]["exitCode"] == 0,
            "actual-host-exit")
    require(actions["comparisonId"] == comparison and actions["runId"] == run_id and actions["runAttempt"] == 1
            and actions["runnerName"] == "runloc-" + comparison and actions["mode"] == "qualification"
            and actions["physicalQualificationPassed"] is True and actions["passed"] is True, "actions-binding")
    require(len(actions["phases"]) == 2 and [p["phase"] for p in actions["phases"]] == ["preflight", "qualification"]
            and all(p["exitCode"] == 0 and p["passed"] is True and p["activeProcesses"] == 0 for p in actions["phases"]), "phase-exits")
    require(receipt["candidate"]["commit"] == candidate and receipt["candidate"]["tree"] == tree
            and receipt["candidate"]["clean"] is True and receipt["controller"]["commit"] == controller
            and receipt["controller"]["clean"] is True, "receipt-source")
    require(receipt["outcome"] == "pass" and receipt["preflightOnly"] is False and receipt["vmQualificationStarted"] is True
            and type(receipt["exitCode"]) is int and type(receipt["childExitCode"]) is int
            and receipt["exitCode"] == receipt["childExitCode"] == 0 and receipt["sourceUnchanged"] is True,
            "full-receipt-outcome")
    require(not any(receipt[k] for k in ("timedOut", "cancelled", "outputOverflow", "outputFailed", "harnessFailure", "controllerFailure")), "receipt-failure")
    require(receipt["requestedAccelerator"] == receipt["observedAccelerator"] == "whpx"
            and receipt["requestedGuestCpus"] == 6 and receipt["overallTimeoutDisabled"] is True, "private-profile")
    require(utc(receipt["startedUtc"]) >= utc(created_utc), "replayed-receipt")
    cleanup = receipt["cleanup"]
    require(cleanup["childExited"] is True and cleanup["activeProcesses"] == 0 and not cleanup["forced"]
            and cleanup["fixtureRemoved"] is True and cleanup["ownershipVerified"] is True, "receipt-cleanup")
    require(supervisor["supervisorLeaseId"] == receipt["supervisorLeaseId"] and supervisor["outcome"] == "pass"
            and supervisor["exitCode"] == 0 and supervisor["physicalQualificationPassed"] is True, "supervisor-binding")
    require(receipt["telemetry"]["complete"] is True and receipt["telemetry"]["recordCount"] > 0, "incomplete-telemetry")
    validate_events(receipt["events"], "whpx")
    validate_identity_bindings(receipt["identities"], receipt["telemetry"], "whpx")
    return "pass"


def validate_hosted(receipt, *, candidate, tree, controller, comparison, run_id, workflow_commit, created_utc):
    require(receipt["schemaVersion"] == 1 and receipt["lane"] == "hosted-tcg"
            and receipt["repository"] == "techrote/ezvm" and receipt["comparisonId"] == comparison
            and receipt["runId"] == run_id and receipt["runAttempt"] == 1
            and receipt["workflowCommit"] == workflow_commit and receipt["runnerEnvironment"] == "github-hosted", "hosted-association")
    require(receipt["candidate"]["commit"] == candidate and receipt["candidate"]["tree"] == tree
            and receipt["candidate"]["clean"] is True and receipt["controller"]["commit"] == controller
            and receipt["controller"]["clean"] is True and receipt["sourceUnchanged"] is True, "hosted-source")
    require(receipt["passed"] is True and receipt["classification"] == "pass"
            and type(receipt["exitCode"]) is int and receipt["exitCode"] == 0
            and type(receipt["preflightExitCode"]) is int and receipt["preflightExitCode"] == 0, "hosted-outcome")
    require(receipt["requestedAccelerator"] == receipt["observedAccelerator"] == "tcg"
            and receipt["whpxExecution"] == "SKIP" and receipt["qualificationCpus"] == 6, "hosted-profile")
    require(utc(receipt["startedUtc"]) >= utc(created_utc), "replayed-hosted-receipt")
    cleanup = receipt["cleanup"]
    require(cleanup["childExited"] is True and type(cleanup["activeProcesses"]) is int
            and cleanup["activeProcesses"] == 0 and cleanup["forced"] is False and cleanup["fixtureRemoved"] is True, "hosted-cleanup")
    require(receipt["telemetry"]["complete"] is True and receipt["telemetry"]["recordCount"] > 0, "hosted-telemetry")
    validate_events(receipt["events"], "tcg")
    validate_identity_bindings(receipt["identities"], receipt["telemetry"], "tcg")
    return "pass"


def validate_identity_bindings(identities, telemetry, accelerator):
    require(identities["expectedImageSha256"] == identities["sourceImageSha256"], "source-image-binding")
    bindings = {"source-image": identities["sourceImageSha256"], "prepared-base": identities["baseImageSha256"]}
    tools = identities["qemuBinaries"]
    require(len(tools) == 2, "tool-count")
    for kind, filename in (("qemu-system", "qemu-system-x86_64.exe"), ("qemu-img", "qemu-img.exe")):
        matched = [t for t in tools if t["name"] == filename]
        require(len(matched) == 1, "tool-identity")
        bindings[kind] = matched[0]["sha256"]
    for kind, expected in bindings.items():
        require(type(expected) is str and re.fullmatch("[a-f0-9]{64}", expected), "identity-digest-format")
        matched = [t for t in telemetry["identities"] if t["kind"] == kind]
        require(len(matched) == 1 and matched[0]["sha256"] == expected, "telemetry-identity-binding")
    guests = identities["guests"]
    require(len(guests) == 10, "stopped-guest-count")
    for root in ("A", "B"):
        for name in ("ezvm010-source", "ezvm010-stateful", "ezvm010-imported", "ezvm012-secondary", "ezvm012-fresh"):
            matched = [g for g in guests if g["root"] == root and g["name"] == name]
            require(len(matched) == 1, "stopped-guest-identity")
            guest = matched[0]
            memory = 4096 if name in {"ezvm010-imported", "ezvm012-secondary"} else 8192
            require(guest["state"] == "STOPPED" and guest["accelerator"] == accelerator
                    and type(guest["cpus"]) is int and guest["cpus"] == 6 and type(guest["memoryMiB"]) is int
                    and guest["memoryMiB"] == memory and re.fullmatch("[a-f0-9]{32}", guest["launchId"]), "stopped-guest-profile")


def decide(private: str, hosted: str, *, quarantined=False):
    require(private in INFRASTRUCTURE | FAILURES | {"pending", "pass", "hosted-only"}, "private-state")
    require(hosted in FAILURES | {"pending", "pass"}, "hosted-state")
    if quarantined or private in FAILURES or hosted in FAILURES:
        return "failure"
    if private == "pass":
        return "accepted-whpx"
    if hosted == "pass":
        return "accepted-tcg"
    return "pending"
