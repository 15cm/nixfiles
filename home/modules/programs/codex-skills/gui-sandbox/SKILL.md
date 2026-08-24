---
name: gui-sandbox
description: Run isolated GPU-backed GUI tests in kazuki's unprivileged LXC sandbox, including task creation, headless Sway/XWayland and CUA interaction, artifact collection, and safe cleanup. Use for this gui-sandbox workflow, not generic GUI, LXC, or Proxmox operations.
---

# GPU GUI sandbox

Use the repository's `gui-sandbox` CLI for desktop test work that needs an NVIDIA-backed, headless Linux GUI. The service is enabled on `kazuki`; it creates one disposable unprivileged LXC from a pinned Ubuntu template and mounts one selected Git worktree at `/workspace`.

Read `docs/gui-test-sandbox.md` in the flake before changing the implementation or when an invariant is unclear. It is the source of truth for the current storage, template, UID/GID map, GPU boundary, CUA version, and artifact contract.

## Safety boundaries

- Never request, receive, store, echo, or pipe a sudo password. Use the configured root-owned CLI; its only passwordless sudo entry is the exact `/run/current-system/sw/bin/gui-sandbox` path. If a Nix switch or systemd operation needs authentication, have the user authenticate in their own terminal.
- Do not use direct `pct`, `pvesm`, or `zfs` commands for sandbox lifecycle mutation. The CLI proves VMID, tag, mount, worktree, and GPU ownership before mutating anything.
- Do not set `GUI_SANDBOX_NO_SUDO=1` outside the mock test suite.
- Never accept software rendering. A task is usable only when creation reports `health: healthy`; stop on llvmpipe, softpipe, SwiftShader, software rasterization, missing NVIDIA renderer/version, failed CUA doctor, failed AT-SPI, non-`ok` CUA `health_report`, invalid accessibility JSON, or missing screenshot.
- Never pass physical `/dev/dri/card*` nodes, the host Wayland or D-Bus socket, the host home, the SSH agent, or sibling worktrees. The intended GPU boundary is NVIDIA control devices plus `/dev/dri/renderD128` and read-only host NVIDIA libraries.
- Never run `template build --replace` until `pct config 9000` confirms the managed template tags. Never replace an unowned VMID.
- Never manually remove task state, worktrees, artifacts, or VMIDs when ownership proof is missing. Let the CLI fail closed and preserve state for review.
- The worktree mount is read-write by design. Choose a disposable canonical worktree when the guest may edit files. Only one active/creating task is supported.

## Preconditions

1. Confirm the current host is `kazuki` when the host matters. Confirm the live configuration contains the CLI:

   ```sh
   command -v gui-sandbox
   gui-sandbox status --json
   ```

   Do not use `sudo -n true` as the sandbox preflight: the configuration intentionally grants passwordless access only to the exact CLI path.

2. Use an absolute repository path below `/home/sinkerine/orca/workspaces` (the configured allowed root). It must resolve to a real Git worktree root owned by host UID/GID `1000:1000`; symlink escapes, nested paths, non-worktrees, and wrong ownership are rejected.

3. Check `gui-sandbox status --json` before creating a task. Do not evict or destroy another active task; initial capacity is one.

## Provision and create

Build the pinned template only when it is absent or intentionally stale:

```sh
gui-sandbox template build
```

Storage bootstrap is idempotent and is also checked by template/task creation. It uses ZFS dataset `rpool/proxmox/agent-sandbox` through Proxmox storage `agent-sandbox`; mismatches fail closed.

Create a task with a short slug and inspect the JSON result:

```sh
gui-sandbox create \
  --task demo \
  --repo /home/sinkerine/orca/workspaces/my-worktree \
  --json
```

Require `state: active` and `health: healthy`. Record the VMID, lease, IP, `workspace_path`, SSH command, GPU identity, and provisioning schema. Creation has already checked the UID/GID map, exact `/workspace` mount, strict SSH host key, NVIDIA renderer/version, Sway/XWayland, CUA display/AT-SPI, accessibility tree, and desktop screenshot.

If creation fails, inspect `gui-sandbox status demo --json` and preserve any creating metadata for review. Do not bypass health checks, switch to software rendering, or destroy a container with direct Proxmox commands.

## Run GUI tests

Run commands from `/workspace`; pass an argument vector after `--`:

```sh
gui-sandbox exec demo -- bash -lc 'make test'
gui-sandbox launch demo -- ./run-native-wayland-test
gui-sandbox launch demo -- ./run-xwayland-test
```

The guest environment provides headless Sway on `wayland-1`, XWayland on the provisioned display, user D-Bus, portals, AT-SPI, and NVIDIA GLVND paths. Verify native Wayland and XWayland behavior separately when the test requires both; do not infer one from the other. Use CUA semantic inspection before coordinate-only actions.

Use the CUA Driver through the wrapper, with one JSON argument:

```sh
gui-sandbox cua demo get_accessibility_tree '{}'
gui-sandbox cua demo get_window_state '{"pid":1234}'
gui-sandbox cua demo get_desktop_state '{}'
gui-sandbox mcp demo
```

CUA Driver `0.21.0` has no separate `screenshot` tool. `get_desktop_state` (and `zoom`) writes a PNG/JPEG through `--screenshot-out-file`, copies it into a task-user-owned artifact directory, and returns `host_artifact`.

For worktree round-trip checks, write a file in the guest, inspect it on the host, write one as host UID/GID `1000:1000`, and inspect it in the guest. Do not test this against an important worktree without explicit user approval.

## Collect and clean up

Collect evidence before intentional cleanup, or use `destroy`, which collects first:

```sh
gui-sandbox collect demo
gui-sandbox destroy demo
```

Artifacts include task metadata, the final pct config, guest health logs, guest Sway/CUA journal output, workspace identity, and any CUA screenshots. An explicit `--dest` must already exist, be task-user-owned, and resolve below the allowed worktree root. Never point it at a broad or shared directory.

`gui-sandbox reap` is the recovery path for expired leases, not routine cleanup. It destroys only expired tasks with managed tags and an exact worktree mount; unmanaged, retagged, or ambiguous tasks are skipped. A failed ownership proof is a reason to stop, not to broaden cleanup.

## Implementation changes

When changing this sandbox or its Nix enablement, preserve unrelated worktree changes and update the source-of-truth doc if behavior changes. Run:

```sh
bash -n hosts/modules/services/gui-test-sandbox/*.sh tests/*.sh
nix shell nixpkgs#shellcheck --command shellcheck \
  hosts/modules/services/gui-test-sandbox/gui-sandbox.sh \
  hosts/modules/services/gui-test-sandbox/guest-provision.sh \
  tests/fake-pct.sh tests/gui-test-sandbox-test.sh
bash tests/gui-test-sandbox-test.sh
git diff --check
nixos-rebuild build --flake .#kazuki
```

Build verification is required on `kazuki`; do not report implementation completion after a build alone when live guest checks remain pending.
