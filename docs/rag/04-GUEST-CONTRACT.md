# 04 — Linux guest bootstrap and readiness

The guest is a single-purpose Ubuntu Linux x64 runner, not a developer workstation.
Cloud-init sets unique lease identity and boot nonce, regenerates machine/SSH
identity and installs only the listed base profile. No shared writable host mount.
The host creates a unique per-lease SSH control identity, restricted to the owned
runtime root. Host public key is per-lease seed data; no private key enters the guest.

`GUEST_READY` requires completed provisioning, exact lease/nonce/image identity,
authenticated SSH and independent host observation of the expected owned QEMU.
Bootstrap attests its SSH host-key fingerprint through the captured host-owned
serial channel before SSH is trusted. Do not use `StrictHostKeyChecking=no`, TOFU
across leases or an inherited global known_hosts file. A stale serial line, open
port or cloud-init process alone is insufficient.

Use a small fixed guest control wrapper with versioned JSON operations, strict
input types and bounded sizes: readiness, write-once runner configuration, start,
status, collect, stop. Transfer configuration using an authenticated stdin/file
channel into guest tmpfs with mode0600, owned by the runner user. Do not place a
JIT blob in process arguments, cloud-init logs, serial output or a persistent base.
Deletion of plaintext configuration is not a claim of secure SSD erasure.

The pinned runner needs a verified non-argv startup route. During planning,
official runner 2.338.0 `CommandSettings` accepted `ACTIONS_RUNNER_INPUT_JITCONFIG`
and removed input variables from its environment after parsing.006/007 must
reverify that behavior and masking on the selected release, set the value only
inside the guest runner child, and test that job children do not inherit it.
Do not assume a wrapper reading stdin makes a later `--jitconfig <secret>` argv
safe, or that an environment variable is intrinsically secret from privileged
process inspection. Existing guest runtime credentials still make the overlay
sensitive and require disposal.

The official runner executes as unprivileged `runner`, never root. Installing the
base profile is a separate build step. The initial supported profile has no Docker
daemon, no host socket and no promise that workflows needing passwordless sudo
will succeed. Capability labels must name the real profile, OS and architecture.

Runner readiness is separate from guest readiness and requires GitHub observation
of the expected repository-scoped registration, name and unique label. Terminal
runner exit is separate from GitHub job success. Capture actual GitHub run/job IDs,
conclusion and runner association; collect logs before shutdown and verify host-side
disposal even when guest reporting is absent or false.

Explicit tests: old boot nonce/identity, forged READY text, wrong host key, partial
provisioning, failed configuration write, runner exits before job, oversized output,
lost SSH, reboot and malicious path in a collection manifest. Guest logs/results
are untrusted data and cannot choose arbitrary host export paths.

See [GitHub](05-GITHUB-RUNNERS.md), [recovery](07-SECURITY-RECOVERY.md),
[acceptance](08-TESTING-ACCEPTANCE.md).
