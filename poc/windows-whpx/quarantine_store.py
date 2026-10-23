"""Persistent failures and explicit, source-bound eligibility recovery.

Recovery never supplies a comparison result. The legacy latch stays unchanged;
only its reviewed exact bytes may be exempted. New failures always block.
"""
from datetime import datetime, timezone
import os
from pathlib import Path
import re
import stat

from qualification_gate import canonical, decide, digest, json_bytes, require, utc

LEGACY = 'ci-poc-003-private-quarantine.json'
STORE = 'ci-poc-003-failures'
ADJUDICATION = 'docs/fast-track/evidence/ci-poc-003-recovery/adjudication.json'


def candidate_valid(candidate):
    return (isinstance(candidate, dict) and set(candidate) == {'commit', 'tree'}
            and all(isinstance(candidate[k], str) and re.fullmatch('[a-f0-9]{40}', candidate[k]) for k in candidate))


def ordinary(path, directory=False):
    info = path.lstat()
    require(not (getattr(info, 'st_file_attributes', 0) & 0x400)
            and (stat.S_ISDIR(info.st_mode) if directory else stat.S_ISREG(info.st_mode))
            and (directory or info.st_nlink == 1), 'ambiguous-quarantine-path')
    return info


def read_small(path):
    before = ordinary(path)
    require(before.st_size <= 16384, 'quarantine-record-too-large')
    with path.open('rb') as stream:
        opened = os.fstat(stream.fileno())
        require((before.st_dev, before.st_ino) == (opened.st_dev, opened.st_ino)
                and stat.S_ISREG(opened.st_mode) and opened.st_nlink == 1
                and not (getattr(opened, 'st_file_attributes', 0) & 0x400), 'quarantine-file-changed')
        raw = stream.read(16385)
    require(len(raw) <= 16384, 'quarantine-record-too-large')
    return raw


def validate_failure(raw, comparison=None):
    value = json_bytes(raw)
    require(isinstance(value, dict) and set(value) == {'schemaVersion', 'candidate', 'comparisonId', 'private', 'hosted', 'utc', 'resetRequires'}
            and type(value['schemaVersion']) is int and value['schemaVersion'] == 1
            and candidate_valid(value['candidate']) and isinstance(value['comparisonId'], str)
            and re.fullmatch('[a-f0-9]{32}', value['comparisonId'])
            and (comparison is None or value['comparisonId'] == comparison)
            and value['resetRequires'] == 'explicit-reviewed-reset'
            and isinstance(value['utc'], str) and utc(value['utc']).tzinfo is not None
            and isinstance(value['private'], str) and isinstance(value['hosted'], str)
            and decide(value['private'], value['hosted'], quarantined=False) == 'failure', 'invalid-quarantine-record')
    return value


def failures(backing):
    store = Path(backing) / STORE
    if not os.path.lexists(store):
        return []
    ordinary(store, directory=True)
    names = list(store.iterdir())
    require(len(names) <= 1000, 'failure-store-inventory-bound')
    for path in names:
        require(re.fullmatch('[a-f0-9]{32}\\.json', path.name), 'unknown-failure-store-entry')
        validate_failure(read_small(path), path.stem)
    return names


def quarantine_blocked(backing, candidate, recovery=None, *, source_root):
    """Malformed, absent required history or unreadable storage always blocks."""
    try:
        require(candidate_valid(candidate), 'quarantine-candidate-invalid')
        # The store is created only after observing an actual failure. Even an
        # empty directory can mean a crash between mkdir and durable recording.
        if failures(backing) or os.path.lexists(Path(backing) / STORE):
            return True
        legacy = Path(backing) / LEGACY
        if not os.path.lexists(legacy):
            return recovery is not None
        raw = read_small(legacy)
        validate_failure(raw)
        if recovery is None:
            return True
        backing_digest = digest(os.path.normcase(str(Path(backing).resolve())).encode())
        require(isinstance(recovery, dict) and set(recovery) == {'schemaVersion', 'candidate', 'legacySha256', 'adjudicationSha256', 'backingRootSha256'}
                and type(recovery['schemaVersion']) is int and recovery['schemaVersion'] == 1
                and recovery['candidate'] == candidate and recovery['legacySha256'] == digest(raw)
                and recovery['backingRootSha256'] == backing_digest
                and re.fullmatch('[a-f0-9]{64}', recovery['adjudicationSha256']), 'unapproved-recovery')
        adjudication_raw = read_small(Path(source_root) / ADJUDICATION)
        require(digest(adjudication_raw) == recovery['adjudicationSha256'], 'recovery-adjudication-digest')
        adjudication = json_bytes(adjudication_raw)
        require(isinstance(adjudication, dict) and set(adjudication) == {'schemaVersion', 'candidate', 'legacySha256',
                    'historicalCauseResolved', 'authorRole', 'reviewerRole', 'reason', 'proofs', 'backingRootSha256'}
                and type(adjudication['schemaVersion']) is int and adjudication['schemaVersion'] == 1
                and adjudication['candidate'] == candidate and adjudication['legacySha256'] == digest(raw)
                and adjudication['backingRootSha256'] == backing_digest
                and adjudication['historicalCauseResolved'] is False
                and adjudication['authorRole'] == 'Codex primary agent'
                and adjudication['reviewerRole'] == 'separate Codex agent'
                and isinstance(adjudication['reason'], str) and 1 <= len(adjudication['reason']) <= 2048, 'recovery-adjudication-invalid')
        proof = adjudication['proofs']
        require(isinstance(proof, dict) and set(proof) == {'physicalReceiptSha256', 'hostedReceiptSha256',
                    'physicalAttemptId', 'hostedRunId', 'controllerCommit', 'controllerTree'}
                and all(isinstance(proof[k], str) and re.fullmatch('[a-f0-9]{64}', proof[k])
                        for k in ('physicalReceiptSha256', 'hostedReceiptSha256'))
                and isinstance(proof['physicalAttemptId'], str) and re.fullmatch('[a-f0-9]{32}', proof['physicalAttemptId'])
                and type(proof['hostedRunId']) is int and proof['hostedRunId'] > 0
                and all(isinstance(proof[k], str) and re.fullmatch('[a-f0-9]{40}', proof[k])
                        for k in ('controllerCommit', 'controllerTree')), 'recovery-proof-identities-invalid')
        return False
    except (OSError, ValueError, TypeError, KeyError, RecursionError):
        return True


def record_failure(backing, candidate, comparison, private, hosted):
    """Caller holds publication lock. Preserve first actual failure, never green."""
    if decide(private, hosted, quarantined=False) != 'failure':
        return
    require(candidate_valid(candidate) and isinstance(comparison, str) and re.fullmatch('[a-f0-9]{32}', comparison), 'failure-identity-invalid')
    store = Path(backing) / STORE
    if not os.path.lexists(store):
        store.mkdir()  # Inherits the qualified backing directory's private DACL.
    ordinary(store, directory=True)
    failures(backing)  # Partial, unknown or ambiguous files cannot be ignored.
    path = store / (comparison + '.json')
    if os.path.lexists(path):
        existing = validate_failure(read_small(path), comparison)
        require(existing['candidate'] == candidate, 'existing-failure-candidate-changed')
        return
    raw = canonical(dict(schemaVersion=1, candidate=candidate, comparisonId=comparison, private=private,
        hosted=hosted, utc=datetime.now(timezone.utc).isoformat(), resetRequires='explicit-reviewed-reset'))
    with path.open('xb') as stream:
        stream.write(raw); stream.flush(); os.fsync(stream.fileno())
    # Older controllers still see a global latch. Never change retained bytes.
    legacy = Path(backing) / LEGACY
    if not os.path.lexists(legacy):
        with legacy.open('xb') as stream:
            stream.write(raw); stream.flush(); os.fsync(stream.fileno())
