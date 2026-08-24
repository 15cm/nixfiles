# GPU-backed LXC GUI test sandbox

Status: implemented in the NixOS kazuki configuration. The host module, root-owned lifecycle CLI, Ubuntu template provisioner, mocked safety tests, and build checks are complete. Real Proxmox template/clone and guest GUI checks remain blocked by missing root authorization on the current session; exact evidence is recorded below.

## Architecture

~~~text
agent + Git worktree on kazuki
  |
  +-- sudo -n gui-sandbox -- pct -- linked, unprivileged task LXC
  |                                      |
  |                                      +-- /workspace worktree bind mount
  |                                      +-- read-only NVIDIA libraries
  |                                      +-- NVIDIA control/render devices
  |                                      +-- SSH -- headless Sway -- XWayland/AT-SPI -- CUA Driver
  |
  +-- root-owned state, leases, locks, SSH host keys, and artifact collection
  +-- ZFS rpool/proxmox/agent-sandbox via Proxmox storage agent-sandbox
~~~

The host never shares its Wayland socket, D-Bus socket, home directory, SSH agent, or sibling worktrees. The guest receives one explicitly selected worktree, a DHCP network interface, and the GPU resources needed by its own headless desktop.

## Implementation

Files:

- hosts/modules/services/gui-test-sandbox/default.nix — NixOS module, options, sudo rule, tmpfiles, storage bootstrap, and lease timer.
- hosts/modules/services/gui-test-sandbox/gui-sandbox.sh — root-owned lifecycle CLI and ownership checks.
- hosts/modules/services/gui-test-sandbox/guest-provision.sh — Ubuntu provisioning, Sway/XWayland, CUA Driver, SSH, and health checks.
- tests/gui-test-sandbox-test.sh and tests/fake-pct.sh — mocked Proxmox safety/interface tests.
- hosts/kazuki/default.nix — kazuki enablement.

The module is imported by hosts/modules/services/default.nix and enabled with:

~~~nix
my.services.guiTestSandbox.enable = true;
~~~

The only passwordless sudo command is the exact system path /run/current-system/sw/bin/gui-sandbox. pct, pvesm, and zfs are runtime dependencies of the root-owned wrappers, not user-authorized sudo commands.

## Host options and defaults

All options live under my.services.guiTestSandbox:

| Option | Default | Purpose |
| --- | --- | --- |
| allowedWorktreeRoot | /home/sinkerine/orca/workspaces | Canonical worktree/artifact boundary. |
| stateDirectory | /var/lib/gui-test-sandbox | Root-owned metadata, lock, SSH, and artifacts. |
| storageDataset | rpool/proxmox/agent-sandbox | ZFS filesystem for task root filesystems. |
| storageId | agent-sandbox | Proxmox zfspool storage ID. |
| templateCache | /var/lib/vz/template/cache | Root-owned template archive directory. |
| templateVmid | 9000 | Reserved managed template VMID. |
| firstVmid / lastVmid | 9100 / 9199 | Managed task VMID range. |
| bridge | vmbr0 | DHCP bridge. |
| cores | 8 | Template/task vCPU count. |
| memoryMiB | 16384 | Template/task memory in MiB. |
| rootfsGiB | 64 | Sparse template root filesystem; clones inherit it. |
| leaseHours | 12 | Task lease duration. |
| guestUid / guestGid | 1000 / 1000 | Guest agent identity; the module asserts these values. |
| subordinateIdStart / subordinateIdCount | 100000 / 65536 | Root subordinate UID/GID range. |
| nvidiaRenderNode | /dev/dri/renderD128 | NVIDIA render node; card nodes are rejected. |
| nvidiaGpuName | NVIDIA GeForce RTX 5070 Ti | Renderer string required by guest health. |
| nvidiaDriverVersion | host NVIDIA package version | Version required by guest health. |
| templateImage | ubuntu-24.04-standard_24.04-2_amd64.tar.zst | Ubuntu Proxmox template filename. |
| templateImageUrl | Proxmox Ubuntu image URL | Download source, SHA-512 verified before use. |
| templateImageSha512 | 45c2978e6b97fe292ada95fe06834276015e5739a594db4de2fdfd830fa0c37942e8ae118fc1e32ffd9154b3f9378b592738b668ea3957db41f2907b86f219de | Template content pin. |
| cuaDriverVersion | 0.21.0 | CUA Driver release. |
| cuaDriverArchiveUrl | CUA Driver GitHub release URL | CUA archive source. |
| cuaDriverArchiveSha256 | b269df39141bf873a583913cf59c18b867f8ac880ba43d781ca276b2632a6f55 | CUA archive content pin. |

The module adds root subordinate ranges, creates state directories with root/task-user ownership, installs the CLI, and enables storage bootstrap plus a persistent 15-minute reaper timer.

## Storage and template lifecycle

After the built configuration is activated, storage bootstrap is idempotent:

~~~sh
sudo systemctl start gui-test-sandbox-storage.service
zfs list rpool/proxmox/agent-sandbox
pvesm config agent-sandbox
~~~

It creates the ZFS filesystem with mountpoint=none, verifies that it is a filesystem, and either verifies an existing agent-sandbox zfspool points at the exact dataset or adds it with rootdir content and sparse volumes. A mismatched existing storage fails closed.

Build the pinned template explicitly:

~~~sh
gui-sandbox template build
~~~

The command:

1. Creates or verifies the root-owned template cache.
2. Downloads the pinned Ubuntu archive when absent and checks SHA-512 every time.
3. Creates VMID 9000 on agent-sandbox as an unprivileged container.
4. Applies the six-line UID/GID map, pushes the pinned CUA archive and provisioner, and starts the guest.
5. Installs GUI, accessibility, SSH, diagnostic, font, FFmpeg, and CUA dependencies.
6. Configures agent UID/GID 1000, linger, headless Sway, XWayland, user D-Bus, portals, SSH restrictions, and CUA.
7. Stops and marks VMID 9000 as a managed template with a provisioning-schema tag.

Provisioning schema includes the guest provisioner, CUA version, NVIDIA version/name, template filename, and template checksum. A stale schema is refused. To intentionally rebuild a managed stale template after reviewing its configuration:

~~~sh
pct config 9000
gui-sandbox template build --replace
~~~

Replace refuses an unowned or non-template VMID. Template creation does not mount host NVIDIA resources; each task clone receives those mounts after cloning.

## UID/GID mapping

For the defaults, every task config receives:

~~~text
lxc.idmap: u 0 100000 1000
lxc.idmap: u 1000 1000 1
lxc.idmap: u 1001 101001 64535
lxc.idmap: g 0 100000 1000
lxc.idmap: g 1000 1000 1
lxc.idmap: g 1001 101001 64535
~~~

Guest UID/GID 1000 remains host UID/GID 1000, so /workspace preserves task-user ownership in both directions. Guest root and all other guest IDs are shifted through root's subordinate range.

The UID-map replacement temp file is created inside /etc/pve/lxc. This is required because Proxmox pmxcfs can be a different filesystem from /var/lib; a state-directory temp cannot be atomically moved into pmxcfs.

## Task creation and GPU boundary

Create one task from a canonical Git worktree:

~~~sh
gui-sandbox create --task demo --repo /home/sinkerine/orca/workspaces/my-worktree --json
~~~

The CLI accepts only slugs matching [a-z0-9][a-z0-9-]{0,47}. The repository must resolve below allowedWorktreeRoot, be a real directory owned by UID/GID 1000, and be the exact Git worktree root. Symlink escapes, missing roots, non-worktrees, and wrong ownership are rejected. Only one active or creating task is allowed.

Creation locks state, verifies the managed template/storage/worktree/GPU, allocates a VMID, generates task SSH material, creates pending metadata, makes a linked clone, applies the map, mounts the worktree and GPU, starts the guest, rotates host keys, discovers DHCP, verifies /workspace, runs guest health as agent, and only then marks state active and health healthy.

The task receives exactly these NVIDIA device nodes:

~~~text
/dev/nvidia0
/dev/nvidiactl
/dev/nvidia-modeset
/dev/nvidia-uvm
/dev/nvidia-uvm-tools
/dev/dri/renderD128
~~~

The host NVIDIA library and binary outputs are separate read-only mounts at /opt/gui-sandbox/host-nvidia and /opt/gui-sandbox/host-nvidia-bin. Physical DRM card nodes are never passed. Host preflight requires the render node to be a character device backed by the NVIDIA driver, all required NVIDIA control devices to exist, and both library outputs to be available.

Inside the guest, WLR_BACKENDS=headless, a 1920x1080 HEADLESS-1 output, GLES2, WLR_RENDERER_ALLOW_SOFTWARE=0, and NVIDIA GLVND paths are enforced. Health fails on an absent renderer, llvmpipe/softpipe/software rasterization/SwiftShader, a GPU-name mismatch, or a driver-version mismatch. It also requires CUA doctor display and AT-SPI probes, health_report overall=ok, accessibility-tree JSON, and a non-empty desktop capture before create can report health=healthy.

## Guest GUI and CUA interface

The provisioner enables:

- gui-sandbox-sway.service — headless Sway with XWayland enabled.
- gui-sandbox-cua.service — CUA Driver 0.21.0 on /run/user/1000/cua-driver.sock in standard permission mode.
- gui-sandbox-health.service — on-demand health oneshot; disabled after provisioning and run synchronously by create.
- OpenSSH restricted to key-authenticated agent; root/password/X11 forwarding/TCP forwarding/agent forwarding/tunnels are disabled.

The CUA archive is extracted into /opt/cua-driver and its executable is installed at /usr/local/bin/cua-driver. The daemon and clients set CUA_DRIVER_RS_ENABLE_WAYLAND=1 so the native Wayland backend is enabled rather than left experimental. The tested 0.21.0 surface uses get_desktop_state for screenshots, get_accessibility_tree/get_window_state for discovery, and click/type_text/press_key for input.

The health check records cua-doctor.json, health-report.json, accessibility-tree.json, desktop-state.json, renderer.txt, and wayland-info.txt under /var/log/gui-sandbox. It captures a health-screenshot.png through the CUA daemon; any failed probe aborts task creation.

Examples:

~~~sh
gui-sandbox cua demo get_accessibility_tree '{}'
gui-sandbox cua demo get_desktop_state '{}'
gui-sandbox cua demo get_window_state '{"pid":1234}'
gui-sandbox mcp demo
~~~

For get_desktop_state and zoom, the CLI uses CUA's --screenshot-out-file option, copies the guest image into a task-user-owned artifact directory, and adds host_artifact to the JSON result. CUA Driver 0.21.0 has no screenshot tool; use get_desktop_state.

Native Wayland applications use the Sway/Wayland environment. GTK/X11 applications use XWayland through GDK_BACKEND=wayland,x11 and QT_QPA_PLATFORM=wayland;xcb. Semantic inspection remains preferred; explicit foreground delivery is available through CUA input tools when an application rejects background input.

## CLI contract

~~~text
gui-sandbox template build [--replace]
gui-sandbox create --task SLUG --repo WORKTREE [--json]
gui-sandbox status [SLUG] [--json]
gui-sandbox exec SLUG -- ARGV...
gui-sandbox launch SLUG -- ARGV...
gui-sandbox cua SLUG TOOL JSON
gui-sandbox mcp SLUG
gui-sandbox collect SLUG [--dest DIRECTORY]
gui-sandbox destroy SLUG [--dest DIRECTORY]
gui-sandbox reap
~~~

create --json returns task, state, health, vmid, ip, workspace, lease_expires, SSH paths, provisioning_schema, and gpu, plus workspace_path, ssh_command, and cua_command. status --json adds expired. exec runs an argument-vector-safe command from /workspace. launch backgrounds a command and logs it under /run/user/1000/gui-sandbox-<task>.log. cua validates JSON before forwarding. mcp exposes CUA's stdio MCP transport over SSH.

## Artifacts, destruction, and leases

collect creates an output directory below /var/lib/gui-test-sandbox/artifacts by default, or below an existing task-user-owned directory under the allowed worktree root with --dest. It writes:

~~~text
task.json
pct-config.txt
guest-health.txt
guest-journal.txt
workspace.txt
~~~

CUA screenshots are stored beside these files when collected through the CUA interface. Output files/directories are task-user-owned; root metadata, locks, and task SSH material remain protected.

destroy first collects artifacts, verifies VMID range, managed/task tags, exact /workspace mount, and metadata, then stops and purges the container. It removes only that task's metadata and SSH directory. It never removes the worktree, artifacts, sibling task, template, or unowned VMID. Failed ownership/mount proof fails closed.

The reaper runs every 15 minutes after boot. Expired active tasks are collected and destroyed. Expired creating tasks are removed only when a managed task tag and exact worktree mount prove ownership; otherwise metadata is retained. Unmanaged or retagged tasks are logged and skipped. The lifecycle lock serializes template, create, collect, destroy, and reap.

## Normal workflow

~~~sh
gui-sandbox status --json
gui-sandbox create --task demo --repo /home/sinkerine/orca/workspaces/my-worktree --json
gui-sandbox exec demo -- bash -lc 'make test'
gui-sandbox launch demo -- ./run-native-wayland-test
gui-sandbox cua demo get_accessibility_tree '{}'
gui-sandbox cua demo get_desktop_state '{}'
gui-sandbox launch demo -- ./run-xwayland-test
gui-sandbox cua demo get_window_state '{"pid":1234}'
gui-sandbox collect demo
gui-sandbox destroy demo
~~~

Use destroy for intentional cleanup so final health and journal artifacts are retained. The timer is a recovery path for expired leases, not a substitute for normal cleanup.

## Trust boundaries and limitations

- The lifecycle CLI is root-owned; the guest is an unprivileged LXC, not a VM. Guest root is shifted and cannot become host root through the configured map.
- The worktree is intentionally read-write. Code running in the guest can modify that selected worktree, but it cannot mount sibling worktrees through this interface.
- NVIDIA device nodes are shared with the host and are exposed mode 0666 inside the dedicated task container. This is required for the mapped UID/GID and is a GPU-driver trust boundary; the physical display card is never exposed.
- vmbr0 provides ordinary DHCP network access. The design does not add a separate network namespace/firewall policy beyond Proxmox/LXC and the guest SSH restrictions; treat guest code as network-capable.
- SSH access is task-specific and strict-host-key checked. No host SSH agent, host D-Bus, host Wayland, or host home is mounted.
- CUA Driver standard permission mode is used. The release may send content-free product telemetry by default; network policy can be tightened separately if that is not acceptable.
- One concurrent task is deliberate initial capacity. A future pool expansion must preserve VMID/tag ownership and reaper proofs.

## Upgrade procedure

1. Change the template, CUA, GPU, or host-driver pin in default.nix.
2. Run the affected host build and review generated CLI paths, storage unit, sudo rule, and schema.
3. Activate the NixOS configuration with root authorization.
4. Review pct config 9000; run gui-sandbox template build --replace only when the expected managed/template tags are present.
5. Create a disposable task and verify health healthy, renderer output, CUA doctor, a native Wayland app, and an XWayland app before normal use.

Never replace a VMID outside the managed template tag boundary. Failed provisioning that cannot prove task ownership deliberately leaves metadata/configuration for manual review.

## Verification evidence

All checks below ran in this worktree on kazuki on 2026-08-23.

| Check | Result |
| --- | --- |
| bash -n on implementation scripts/tests | Passed. |
| ShellCheck via nix shell nixpkgs#shellcheck --command shellcheck | Passed with no diagnostics. |
| bash tests/gui-test-sandbox-test.sh | Passed path containment, symlink escape, exact UID/GID map, tags, lock, stale template, storage command shape, SSH quoting including an `env` task slug, screenshot artifact ownership, safe reaping, unmanaged skip, and creating-task cleanup. |
| nixos-rebuild build --flake .#kazuki | Passed. Final output: /nix/store/0l7dj0aqs74844h2142ll30xpxb5h5zv-nixos-system-kazuki-26.11.20260819.ffb3c9b. |
| CUA archive SHA-256 | b269df39141bf873a583913cf59c18b867f8ac880ba43d781ca276b2632a6f55. |
| Ubuntu template SHA-512 | Verified with nix store prefetch-file; store path /nix/store/chgin4k0yc1vn2ar7v3an2ld3g30bdah-ubuntu-24.04-standard_24.04-2_amd64.tar.zst. |
| CUA archive execution | manifest, describe, doctor --json, native-Wayland opt-in, and get_desktop_state --screenshot-out-file syntax verified for 0.21.0. |
| Native CUA protocol probe | With CUA_DRIVER_RS_ENABLE_WAYLAND=1, health_report reported wayland_backend pass; get_accessibility_tree returned an object and get_desktop_state wrote a 1,236,303-byte PNG. Host AT-SPI remained unavailable, so overall was degraded. |
| Host GPU | nvidia-smi reported NVIDIA GeForce RTX 5070 Ti, 595.91.07; GLX/EGL reported NVIDIA RTX 5070 Ti, not software rendering; renderD128 resolves to the NVIDIA driver. |
| Host identity | Hostname kazuki; sinkerine UID/GID 1000:1000; subordinate range 100000:65536 present for sinkerine. |
| Generated system inspection | Final wrapper PATH contains Proxmox and ZFS tools; generated sudoers contains only the exact gui-sandbox NOPASSWD rule; generated tmpfiles and storage/reaper units are present. |

The mock suite executes the real shell functions and CLI against fake pct, ZFS, Proxmox storage, and SSH commands without mutating host state.

## Current external blocker

No real Proxmox mutation or guest e2e was performed. Root authorization is unavailable:

~~~text
sudo -n true
sudo: a password is required
~~~

The same failure occurred for safe read-only sudo attempts with sudo -n pct list, sudo -n pvesm status, and sudo -n zfs list. Direct non-root checks showed:

- zfs list is readable and shows rpool/proxmox, but rpool/proxmox/agent-sandbox does not yet exist.
- Direct pvesm status cannot access Proxmox IPC/ACL without authorization.
- Direct pct list fails in the current live system because its wrapper cannot locate PVE::CLI::pct.
- The final configuration is built but not switched into the live host; switching and Proxmox lifecycle operations require root authorization.
- A non-root CUA daemon probe returned health_report overall=degraded because the current host D-Bus has no activatable org.a11y.Bus; this is host evidence only, not guest health evidence.

Once authorization is available, the remaining commands are:

~~~sh
sudo nixos-rebuild switch --flake .#kazuki
sudo systemctl start gui-test-sandbox-storage.service
gui-sandbox template build
gui-sandbox create --task e2e --repo /home/sinkerine/orca/workspaces/disposable-worktree --json
gui-sandbox cua e2e health_report '{}'
gui-sandbox cua e2e get_desktop_state '{}'
gui-sandbox collect e2e
gui-sandbox destroy e2e
~~~

Those commands must confirm guest renderer/version, health healthy, CUA doctor, AT-SPI/window discovery, native Wayland and XWayland apps, bidirectional UID/GID-1000 worktree edits, host GUI usability, and TTL cleanup. Until root authorization and live Proxmox services are available, the implementation intentionally refuses to claim those checks passed.
