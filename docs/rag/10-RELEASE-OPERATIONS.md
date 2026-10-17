# 10 — Release, operating guide and future work

The source package is small. Distribute Runloc code, schemas, recipes, verified
input manifests, examples and notices; fetch third-party runtimes/images separately.
No VM disks, seeded media, registration/key files or personal host state in packages.
MIT applies only to Runloc's own work. Check each dependency's actual terms before
copying/redistributing code or binaries; public visibility alone is not permission.

Initial operator path: install supported Python, obtain Runloc source/package,
`doctor`, deliberate verified tool acquisition, image build, credential-provider
preflight, preview, one approved repository/job lease, evidence, disposal check.
Document every needed permission, download/space estimate, trust limitation,
timeout, exact supported shell-action profile, known host prerequisites and reset/
recovery procedure. Runtime commands are not advertised as available before001.
Avoid optimistic one-click claims while host features or credentials need setup.

Publish trusted hosted/private template examples with pinned action revisions,
least required workflow permissions, exact candidate input, unique lease label,
comparison ID and approved definition. No live registration or private execution
on installation, normal PR CI or a documentation preview. Example repository must
be explicitly approved for the real qualification and contain no production secrets.

Updates replace verified tools/base images atomically; running leases retain their
old immutable identities. Refuse stale runner versions according to current GitHub
policy, explain rebuild commands and preserve prior valid inputs until unreferenced.
Package install/uninstall must not remove another project's QEMU, PATH entries,
owner VMs or credentials. Repair/reconcile and retention use exact scope previews.

V0.1 release evidence includes014's exact tag/source,001–013 acceptance, all required
checks, pilot and recovery receipts, actual platform/profile matrix, limitations,
manifest/SBOM/notices, fresh directory reproduction and upgrade/rollback checks.
Changing main status or publishing a wheel is not physical qualification.

Follow-on015 adds bounded multi-lease capacity,016 a Windows guest feasibility
decision (licensing, image recipe and nested-virtualization evidence),017 Linux/KVM,
018 evaluation of official scale-set integration/other CI,019 a private acceptance
gate. None is silently enabled by the v0.1 release. Unsupported feasibility outcomes
remain clearly documented and cannot be promoted to supported feature labels.

See [scope](00-SCOPE.md), [security](07-SECURITY-RECOVERY.md),
[testing](08-TESTING-ACCEPTANCE.md), [programme](../programme/IMPLEMENTATION-PROGRAMME.md).
