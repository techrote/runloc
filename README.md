# Runloc

Disposable QEMU virtual machines for on-demand GitHub Actions runners.

**Status: reviewed implementation programme; the runner product is not implemented.**
The repository contains the programme, autonomous issue prompts, RAG contracts and
fast documentation checks. Planned CLI examples are interfaces to implement, not
commands that work today.

The first release targets **Linux x64 runners in fresh VMs on a Windows 11 x64
host using WHPX**. Each guest accepts one job and is then destroyed. Windows
guests and Linux/KVM hosts are separate follow-on work. A Linux guest cannot
replace a Windows CI job or qualify nested WHPX.

Start with the [implementation programme](docs/programme/IMPLEMENTATION-PROGRAMME.md),
[review and revisions](docs/programme/PLAN-REVIEW.md), [agent instructions](AGENTS.md)
and [RAG index](docs/rag/README.md). Each implementation issue links everything
needed for its own build, tests, PR and evidence-gated merge.

Runloc is a separate project inspired by the EzVM field test. It does not depend
on a local EzVM checkout, import its owner patches or claim its incomplete pilot
as a benchmark. See [research](docs/research/EZVM-FIELD-NOTES.md).

## Intended first-release experience

1. Check host prerequisites without changing host settings.
2. Fetch verified tools and build a reusable, credential-free Linux runner base.
3. Preview a job's repository, candidate SHA, resource limits and lifetime.
4. Create a fresh overlay, boot, inject single-use runner configuration and execute
   one explicitly approved GitHub job.
5. Preserve bounded diagnostics and results, deregister and destroy the guest.

No Docker, Kubernetes, WSL, bridged adapter or background host service is required.
The first profile supports ordinary shell actions; Docker actions/service containers
require a separately qualified guest profile. General public-fork execution is
outside the initial trust contract.

## Repository checks available now

```text
python scripts/check_repository.py
python -m unittest discover -s tests -p "test_*.py"
```

Python 3.12 is the initial development baseline. Hosted Windows and Ubuntu checks
validate the programme without credentials, hypervisors or public API calls.
Runloc's own code and documentation use [MIT](LICENSE); third-party components
remain governed by their own terms. No third-party VM or runner binaries are
distributed by this planning repository.
