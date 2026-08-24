#!/usr/bin/env bash

# shellcheck disable=SC2016

set -euo pipefail
umask 077

if [[ ${EUID:-$(id -u)} -ne 0 && ${GUI_SANDBOX_NO_SUDO:-0} != 1 ]]; then
  exec sudo -n /run/current-system/sw/bin/gui-sandbox "$@"
fi

: "${GUI_SANDBOX_STATE_DIR:=/var/lib/gui-test-sandbox}"
: "${GUI_SANDBOX_TASK_DIR:=$GUI_SANDBOX_STATE_DIR/tasks}"
: "${GUI_SANDBOX_ARTIFACT_DIR:=$GUI_SANDBOX_STATE_DIR/artifacts}"
: "${GUI_SANDBOX_SSH_DIR:=$GUI_SANDBOX_STATE_DIR/ssh}"
: "${GUI_SANDBOX_LOCK_FILE:=$GUI_SANDBOX_STATE_DIR/lock}"
: "${GUI_SANDBOX_ALLOWED_WORKTREE_ROOT:=/home/sinkerine/orca/workspaces}"
: "${GUI_SANDBOX_STORAGE_ID:=agent-sandbox}"
: "${GUI_SANDBOX_STORAGE_DATASET:=rpool/proxmox/agent-sandbox}"
: "${GUI_SANDBOX_STORAGE_CONFIG:=/etc/pve/storage.cfg}"
: "${GUI_SANDBOX_TEMPLATE_CACHE:=/var/lib/vz/template/cache}"
: "${GUI_SANDBOX_TEMPLATE_VMID:=9000}"
: "${GUI_SANDBOX_FIRST_VMID:=9100}"
: "${GUI_SANDBOX_LAST_VMID:=9199}"
: "${GUI_SANDBOX_BRIDGE:=vmbr0}"
: "${GUI_SANDBOX_CORES:=8}"
: "${GUI_SANDBOX_MEMORY_MIB:=16384}"
: "${GUI_SANDBOX_ROOTFS_GIB:=64}"
: "${GUI_SANDBOX_LEASE_SECONDS:=43200}"
: "${GUI_SANDBOX_GUEST_UID:=1000}"
: "${GUI_SANDBOX_GUEST_GID:=1000}"
: "${GUI_SANDBOX_SUBID_START:=100000}"
: "${GUI_SANDBOX_SUBID_COUNT:=65536}"
: "${GUI_SANDBOX_RENDER_NODE:=/dev/dri/renderD128}"
: "${GUI_SANDBOX_GPU_NAME:=NVIDIA GeForce RTX 5070 Ti}"
: "${GUI_SANDBOX_NVIDIA_PACKAGE:=}"
: "${GUI_SANDBOX_NVIDIA_BIN:=}"
: "${GUI_SANDBOX_NVIDIA_VERSION:=}"
: "${GUI_SANDBOX_TEMPLATE_IMAGE:=ubuntu-24.04-standard_24.04-2_amd64.tar.zst}"
: "${GUI_SANDBOX_TEMPLATE_URL:=http://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst}"
: "${GUI_SANDBOX_TEMPLATE_SHA512:=45c2978e6b97fe292ada95fe06834276015e5739a594db4de2fdfd830fa0c37942e8ae118fc1e32ffd9154b3f9378b592738b668ea3957db41f2907b86f219de}"
: "${GUI_SANDBOX_CUA_ARCHIVE:=}"
: "${GUI_SANDBOX_CUA_VERSION:=0.21.0}"
: "${GUI_SANDBOX_CUA_SHA256:=b269df39141bf873a583913cf59c18b867f8ac880ba43d781ca276b2632a6f55}"
: "${GUI_SANDBOX_PROVISION_SCHEMA:=}"
: "${GUI_SANDBOX_GUEST_PROVISION:=}"
: "${GUI_SANDBOX_PVE_CONFIG_DIR:=/etc/pve/lxc}"
: "${GUI_SANDBOX_TARGET_UID:=1000}"
: "${GUI_SANDBOX_TARGET_GID:=1000}"
: "${GUI_SANDBOX_PCT:=pct}"
: "${GUI_SANDBOX_PVESM:=pvesm}"
: "${GUI_SANDBOX_ZFS:=zfs}"
: "${GUI_SANDBOX_CURL:=curl}"
: "${GUI_SANDBOX_SSH:=ssh}"
: "${GUI_SANDBOX_SCP:=scp}"
: "${GUI_SANDBOX_SSH_KEYSCAN:=ssh-keyscan}"
: "${GUI_SANDBOX_SSH_KEYGEN:=ssh-keygen}"

managed_tag=gui-sandbox-managed
template_tag=gui-sandbox-template
task_prefix=gui-sandbox-task-
schema_prefix=gui-sandbox-schema-

die() {
  printf 'gui-sandbox: %s\n' "$*" >&2
  exit 1
}

note() {
  printf 'gui-sandbox: %s\n' "$*" >&2
}

numeric() {
  [[ $1 =~ ^[0-9]+$ ]]
}

safe_task() {
  [[ ${1:-} =~ ^[a-z0-9][a-z0-9-]{0,47}$ ]] || die "invalid task slug: ${1:-<empty>}"
}

setup_state() {
  if [[ ${GUI_SANDBOX_TEST_MODE:-0} == 1 ]]; then
    install -d -m 0750 "$GUI_SANDBOX_STATE_DIR" "$GUI_SANDBOX_SSH_DIR"
    install -d -m 0700 "$GUI_SANDBOX_TASK_DIR"
    install -d -m 0750 "$GUI_SANDBOX_ARTIFACT_DIR"
  else
    install -d -o root -g "$GUI_SANDBOX_TARGET_GID" -m 0750 "$GUI_SANDBOX_STATE_DIR" "$GUI_SANDBOX_SSH_DIR" "$GUI_SANDBOX_ARTIFACT_DIR"
    install -d -o root -g root -m 0700 "$GUI_SANDBOX_TASK_DIR"
  fi
}

acquire_lock() {
  exec {lock_fd}>"$GUI_SANDBOX_LOCK_FILE"
  flock -n "$lock_fd" || die 'another gui-sandbox operation is in progress'
}

meta_path() {
  local task=$1
  safe_task "$task"
  printf '%s/%s.json\n' "$GUI_SANDBOX_TASK_DIR" "$task"
}

require_meta() {
  local task=$1 path
  path=$(meta_path "$task")
  [[ -f $path && ! -L $path ]] || die "unknown task: $task"
  if [[ ${GUI_SANDBOX_TEST_MODE:-0} != 1 ]]; then
    [[ $(stat -c '%u:%g:%a' "$path") == 0:0:* ]] || die "unsafe task metadata ownership: $path"
  fi
  printf '%s\n' "$path"
}

meta_get() {
  local task=$1 field=$2 path
  path=$(require_meta "$task")
  jq -er --arg field "$field" '.[$field]' "$path"
}

write_meta() {
  local task=$1 state=$2 vmid=$3 workspace=$4 repo=$5 ip=$6 lease=$7 key=$8 known_hosts=$9 path tmp
  path=$(meta_path "$task")
  tmp=$(mktemp "$GUI_SANDBOX_TASK_DIR/.${task}.XXXXXX")
  jq -n \
    --arg task "$task" \
    --arg state "$state" \
    --argjson vmid "$vmid" \
    --arg workspace "$workspace" \
    --arg repo "$repo" \
    --arg ip "$ip" \
    --argjson lease_expires "$lease" \
    --arg key "$key" \
    --arg known_hosts "$known_hosts" \
    --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg schema "$GUI_SANDBOX_PROVISION_SCHEMA" \
    --arg gpu "$GUI_SANDBOX_GPU_NAME" \
    '{task:$task,state:$state,health:"pending",vmid:$vmid,workspace:$workspace,repo:$repo,ip:$ip,lease_expires:$lease_expires,created_at:$created_at,ssh_key:$key,known_hosts:$known_hosts,provisioning_schema:$schema,gpu:$gpu}' \
    > "$tmp"
  chmod 0600 "$tmp"
  [[ ${GUI_SANDBOX_TEST_MODE:-0} == 1 ]] || chown root:root "$tmp"
  mv -f "$tmp" "$path"
}

update_meta() {
  local task=$1 filter=$2 path tmp
  path=$(require_meta "$task")
  tmp=$(mktemp "$GUI_SANDBOX_TASK_DIR/.${task}.XXXXXX")
  jq "$filter" "$path" > "$tmp"
  chmod 0600 "$tmp"
  [[ ${GUI_SANDBOX_TEST_MODE:-0} == 1 ]] || chown root:root "$tmp"
  mv -f "$tmp" "$path"
}

all_meta_paths() {
  local path
  shopt -s nullglob
  for path in "$GUI_SANDBOX_TASK_DIR"/*.json; do
    [[ -f $path && ! -L $path ]] && printf '%s\n' "$path"
  done
  shopt -u nullglob
}

active_task() {
  local path state
  while IFS= read -r path; do
    state=$(jq -r '.state // empty' "$path")
    if [[ $state == active || $state == creating ]]; then
      jq -r '.task' "$path"
      return 0
    fi
  done < <(all_meta_paths)
  return 1
}

under_root() {
  local candidate=$1 root=$2
  [[ $candidate == "$root" || $candidate == "$root"/* ]]
}

validate_worktree() {
  local requested=$1 root resolved git_root owner
  [[ -n $requested && $requested != -* ]] || die 'repo path is required'
  root=$(realpath -e -- "$GUI_SANDBOX_ALLOWED_WORKTREE_ROOT") || die 'allowed worktree root is missing'
  resolved=$(realpath -e -- "$requested") || die "repo path does not exist: $requested"
  under_root "$resolved" "$root" || die "repo path escapes allowed root: $requested"
  [[ -d $resolved && ! -L $resolved ]] || die 'repo path must resolve to a directory'
  owner=$(stat -c '%u:%g' -- "$resolved")
  [[ $owner == "$GUI_SANDBOX_TARGET_UID:$GUI_SANDBOX_TARGET_GID" ]] || {
    die "worktree must be owned by UID/GID $GUI_SANDBOX_TARGET_UID/$GUI_SANDBOX_TARGET_GID (got $owner)"
  }
  git_root=$(git -C "$resolved" rev-parse --show-toplevel 2>/dev/null) || die 'repo is not a Git worktree'
  git_root=$(realpath -e -- "$git_root") || die 'Git worktree root cannot be resolved'
  [[ $git_root == "$resolved" ]] || die 'repo argument must be the worktree root'
  printf '%s\n' "$resolved"
}

config_for() {
  local vmid=$1
  "$GUI_SANDBOX_PCT" config "$vmid" 2>/dev/null
}

tag_in_config() {
  local config=$1 wanted=$2 tags
  tags=$(printf '%s\n' "$config" | sed -n 's/^tags: //p' | tr ';,' '\n')
  printf '%s\n' "$tags" | grep -Fxq "$wanted"
}

managed_config() {
  local vmid=$1 task=${2:-} config
  numeric "$vmid" || return 1
  ((vmid >= GUI_SANDBOX_FIRST_VMID && vmid <= GUI_SANDBOX_LAST_VMID)) || return 1
  config=$(config_for "$vmid") || return 1
  tag_in_config "$config" "$managed_tag" || return 1
  if [[ -n $task ]]; then
    tag_in_config "$config" "$task_prefix$task" || return 1
  fi
  printf '%s\n' "$config"
}

vmid_in_use() {
  local vmid=$1
  config_for "$vmid" >/dev/null 2>&1
}

allocate_vmid() {
  local vmid
  for ((vmid = GUI_SANDBOX_FIRST_VMID; vmid <= GUI_SANDBOX_LAST_VMID; vmid++)); do
    if ! vmid_in_use "$vmid"; then
      printf '%s\n' "$vmid"
      return 0
    fi
  done
  die "no free VMID in ${GUI_SANDBOX_FIRST_VMID}-${GUI_SANDBOX_LAST_VMID}"
}

template_current() {
  local config
  config=$(config_for "$GUI_SANDBOX_TEMPLATE_VMID") || return 1
  printf '%s\n' "$config" | grep -Fxq 'template: 1' || return 1
  tag_in_config "$config" "$managed_tag" || return 1
  tag_in_config "$config" "$template_tag" || return 1
  tag_in_config "$config" "$schema_prefix$GUI_SANDBOX_PROVISION_SCHEMA" || return 1
}

verify_sha512() {
  local file=$1 actual
  actual=$(sha512sum "$file" | awk '{print $1}')
  [[ $actual == "$GUI_SANDBOX_TEMPLATE_SHA512" ]] || {
    die "template SHA-512 mismatch: expected $GUI_SANDBOX_TEMPLATE_SHA512, got $actual"
  }
}

template_archive() {
  local path="$GUI_SANDBOX_TEMPLATE_CACHE/$GUI_SANDBOX_TEMPLATE_IMAGE"
  install -d -o root -g root -m 0755 "$GUI_SANDBOX_TEMPLATE_CACHE"
  [[ -d $GUI_SANDBOX_TEMPLATE_CACHE && ! -L $GUI_SANDBOX_TEMPLATE_CACHE ]] || die 'template cache is not a real directory'
  [[ $(stat -c '%u:%g' -- "$GUI_SANDBOX_TEMPLATE_CACHE") == 0:0 ]] || die 'template cache has unsafe ownership'
  if [[ -e $path && ( ! -f $path || -L $path ) ]]; then
    die "template archive is not a regular file: $path"
  fi
  if [[ ! -f $path ]]; then
    local tmp
    tmp=$(mktemp "$GUI_SANDBOX_TEMPLATE_CACHE/.${GUI_SANDBOX_TEMPLATE_IMAGE}.XXXXXX")
    note "downloading pinned Ubuntu template"
    "$GUI_SANDBOX_CURL" --fail --location --proto '=http,https' --tlsv1.2 "$GUI_SANDBOX_TEMPLATE_URL" -o "$tmp"
    verify_sha512 "$tmp"
    chmod 0644 "$tmp"
    chown root:root "$tmp"
    mv -f "$tmp" "$path"
  fi
  [[ $(stat -c '%u:%g' -- "$path") == 0:0 ]] || die 'template archive has unsafe ownership'
  verify_sha512 "$path"
  printf '%s\n' "$path"
}

idmap_lines() {
  local high=$((GUI_SANDBOX_SUBID_START + 1000))
  local tail=$((GUI_SANDBOX_SUBID_COUNT - 1001))
  printf 'lxc.idmap: u 0 %s 1000\n' "$GUI_SANDBOX_SUBID_START"
  printf 'lxc.idmap: u %s %s 1\n' "$GUI_SANDBOX_GUEST_UID" "$GUI_SANDBOX_TARGET_UID"
  printf 'lxc.idmap: u 1001 %s %s\n' "$((high + 1))" "$tail"
  printf 'lxc.idmap: g 0 %s 1000\n' "$GUI_SANDBOX_SUBID_START"
  printf 'lxc.idmap: g %s %s 1\n' "$GUI_SANDBOX_GUEST_GID" "$GUI_SANDBOX_TARGET_GID"
  printf 'lxc.idmap: g 1001 %s %s\n' "$((high + 1))" "$tail"
}

apply_idmap() {
  local vmid=$1 path="$GUI_SANDBOX_PVE_CONFIG_DIR/$1.conf" tmp
  [[ -f $path && ! -L $path ]] || die "missing Proxmox config for VMID $vmid"
  if [[ ${GUI_SANDBOX_TEST_MODE:-0} != 1 ]]; then
    [[ $(stat -c '%u:%g' -- "$path") == 0:0 ]] || die "unsafe Proxmox config ownership: $path"
  fi
  # Keep the replacement in /etc/pve.  pmxcfs is commonly a separate
  # filesystem, so a state-directory temp cannot be atomically moved there.
  tmp=$(mktemp "$GUI_SANDBOX_PVE_CONFIG_DIR/.${vmid}.conf.XXXXXX")
  awk '!/^lxc\.idmap:/' "$path" > "$tmp"
  idmap_lines >> "$tmp"
  chmod 0640 "$tmp"
  [[ ${GUI_SANDBOX_TEST_MODE:-0} == 1 ]] || chown root:root "$tmp"
  mv -f "$tmp" "$path"
  local config
  config=$(config_for "$vmid") || die "cannot reread Proxmox config for VMID $vmid"
  [[ $(printf '%s\n' "$config" | grep -c '^lxc.idmap:') -eq 6 ]] || die "UID/GID map was not applied to VMID $vmid"
}

check_gpu_host() {
  [[ $GUI_SANDBOX_RENDER_NODE != */card* ]] || die 'physical-display DRM card passed as render node'
  [[ -c $GUI_SANDBOX_RENDER_NODE ]] || die "NVIDIA render node missing: $GUI_SANDBOX_RENDER_NODE"
  local node driver
  node=$(basename "$GUI_SANDBOX_RENDER_NODE")
  driver=$(readlink -f "/sys/class/drm/$node/device/driver" 2>/dev/null || true)
  [[ $driver == */nvidia ]] || die "render node is not backed by NVIDIA: $GUI_SANDBOX_RENDER_NODE ($driver)"
  [[ -n $GUI_SANDBOX_NVIDIA_PACKAGE && -d $GUI_SANDBOX_NVIDIA_PACKAGE/lib ]] || die 'host NVIDIA library path is unavailable'
  [[ -n $GUI_SANDBOX_NVIDIA_BIN && -d $GUI_SANDBOX_NVIDIA_BIN ]] || die 'host NVIDIA binary output is unavailable'
  [[ -n $GUI_SANDBOX_NVIDIA_VERSION ]] || die 'host NVIDIA driver version is unavailable'
  local device
  for device in /dev/nvidia0 /dev/nvidiactl /dev/nvidia-modeset /dev/nvidia-uvm /dev/nvidia-uvm-tools; do
    [[ -c $device ]] || die "required NVIDIA device missing: $device"
  done
}

ensure_storage() {
  local dataset=$GUI_SANDBOX_STORAGE_DATASET storage_id=$GUI_SANDBOX_STORAGE_ID storage_type storage_block
  if ! "$GUI_SANDBOX_ZFS" list -H -o name "$dataset" >/dev/null 2>&1; then
    "$GUI_SANDBOX_ZFS" create -p -o mountpoint=none "$dataset"
  fi
  [[ $("$GUI_SANDBOX_ZFS" get -H -o value type "$dataset") == filesystem ]] || die "storage dataset is not a ZFS filesystem: $dataset"
  if [[ -e $GUI_SANDBOX_STORAGE_CONFIG && ! -r $GUI_SANDBOX_STORAGE_CONFIG ]]; then
    die "Proxmox storage config is not readable: $GUI_SANDBOX_STORAGE_CONFIG"
  fi
  storage_type=$(awk -v expected="$storage_id" '
    /^[^[:space:]]/ && $2 == expected {
      type = $1
      sub(/:$/, "", type)
      print type
      exit
    }
  ' "$GUI_SANDBOX_STORAGE_CONFIG" 2>/dev/null || true)
  if [[ -n $storage_type ]]; then
    [[ $storage_type == zfspool ]] || die "existing Proxmox storage $storage_id is not zfspool"
    storage_block=$(awk -v expected="$storage_id" '
      /^[^[:space:]]/ {
        in_target = ($2 == expected)
        next
      }
      in_target { print }
    ' "$GUI_SANDBOX_STORAGE_CONFIG")
    printf '%s\n' "$storage_block" | awk -v expected="$dataset" '$1 == "pool" && $2 == expected { found = 1 } END { exit !found }' || die "existing Proxmox storage $storage_id points at a different pool"
  else
    "$GUI_SANDBOX_PVESM" add zfspool "$storage_id" --pool "$dataset" --content rootdir --sparse 1
  fi
}

set_container_config() {
  local vmid=$1 task=$2 workspace=$3
  "$GUI_SANDBOX_PCT" set "$vmid" \
    --hostname "$task" \
    --cores "$GUI_SANDBOX_CORES" \
    --memory "$GUI_SANDBOX_MEMORY_MIB" \
    --swap 0 \
    --net0 "name=eth0,bridge=$GUI_SANDBOX_BRIDGE,ip=dhcp,type=veth" \
    --mp0 "$workspace,mp=/workspace,backup=0,mountoptions=nodev;nosuid" \
    --mp1 "$GUI_SANDBOX_NVIDIA_PACKAGE,mp=/opt/gui-sandbox/host-nvidia,ro=1,backup=0" \
    --mp2 "$GUI_SANDBOX_NVIDIA_BIN,mp=/opt/gui-sandbox/host-nvidia-bin,ro=1,backup=0" \
    --tags "$managed_tag;$task_prefix$task;$schema_prefix$GUI_SANDBOX_PROVISION_SCHEMA" \
    --unprivileged 1

  local device index=0
  for device in /dev/nvidia0 /dev/nvidiactl /dev/nvidia-modeset /dev/nvidia-uvm /dev/nvidia-uvm-tools "$GUI_SANDBOX_RENDER_NODE"; do
    "$GUI_SANDBOX_PCT" set "$vmid" "--dev$index" "$device,mode=0666"
    index=$((index + 1))
  done
}

wait_running() {
  local vmid=$1 i status
  for ((i = 0; i < 60; i++)); do
    status=$("$GUI_SANDBOX_PCT" status "$vmid" 2>/dev/null || true)
    if printf '%s\n' "$status" | grep -Eq 'status: running|running'; then
      return 0
    fi
    sleep 1
  done
  die "container $vmid did not become running"
}

guest_exec() {
  local vmid=$1
  shift
  "$GUI_SANDBOX_PCT" exec "$vmid" -- "$@"
}

guest_exec_shell() {
  local vmid=$1 script=$2
  guest_exec "$vmid" /bin/sh -c "$script"
}

guest_ip() {
  local vmid=$1 ip i
  for ((i = 0; i < 60; i++)); do
    ip=$(guest_exec_shell "$vmid" "ip -4 -o addr show dev eth0 scope global | awk '{split(\$4,a,\"/\"); print a[1]; exit}'" 2>/dev/null || true)
    ip=${ip//$'\n'/}
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ && $ip != 0.0.0.0 ]]; then
      printf '%s\n' "$ip"
      return 0
    fi
    sleep 1
  done
  die "container $vmid did not receive an IPv4 address"
}

create_ssh_material() {
  local task=$1 dir="$GUI_SANDBOX_SSH_DIR/$1"
  install -d -o root -g root -m 0700 "$dir"
  "$GUI_SANDBOX_SSH_KEYGEN" -q -t ed25519 -N '' -C "gui-sandbox-$task" -f "$dir/id_ed25519"
  chmod 0600 "$dir/id_ed25519"
  chmod 0644 "$dir/id_ed25519.pub"
  chown "$GUI_SANDBOX_TARGET_UID:$GUI_SANDBOX_TARGET_GID" "$dir/id_ed25519" "$dir/id_ed25519.pub"
  chown "$GUI_SANDBOX_TARGET_UID:$GUI_SANDBOX_TARGET_GID" "$dir"
  chmod 0700 "$dir"
  printf '%s\n' "$dir"
}

install_guest_ssh_key() {
  local vmid=$1 key_dir=$2
  "$GUI_SANDBOX_PCT" push "$vmid" "$key_dir/id_ed25519.pub" /tmp/gui-sandbox-authorized_key
  guest_exec_shell "$vmid" 'install -d -o agent -g agent -m 0700 /home/agent/.ssh && install -o agent -g agent -m 0600 /tmp/gui-sandbox-authorized_key /home/agent/.ssh/authorized_keys && rm -f /tmp/gui-sandbox-authorized_key'
  guest_exec_shell "$vmid" 'rm -f /etc/ssh/ssh_host_* && ssh-keygen -A && systemctl restart ssh.service'
}

ssh_options() {
  local task=$1 key_dir="$GUI_SANDBOX_SSH_DIR/$1"
  printf '%s\n' \
    -i "$key_dir/id_ed25519" \
    -o UserKnownHostsFile="$key_dir/known_hosts" \
    -o StrictHostKeyChecking=yes \
    -o HashKnownHosts=yes \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    -o ServerAliveInterval=5 \
    -o ServerAliveCountMax=2
}

shell_quote() {
  local value=$1
  value=${value//\'/\'\\\'\'}
  printf "'%s'" "$value"
}

ssh_task() {
  local task=$1 ip key_dir command quoted arg
  shift
  ip=$(meta_get "$task" ip)
  key_dir="$GUI_SANDBOX_SSH_DIR/$task"
  command=
  for arg in "$@"; do
    quoted=$(shell_quote "$arg")
    command+=" $quoted"
  done
  local -a opts=()
  mapfile -t opts < <(ssh_options "$task")
  "$GUI_SANDBOX_SSH" "${opts[@]}" "agent@$ip" "$command"
}

copy_guest_output() {
  local task=$1 remote=$2 output=$3
  local tmp
  tmp=$(mktemp "$(dirname "$output")/.tmp.XXXXXX")
  if ! ssh_task "$task" env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 cat "$remote" > "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  mv -f "$tmp" "$output"
  chown "$GUI_SANDBOX_TARGET_UID:$GUI_SANDBOX_TARGET_GID" "$output"
}

make_artifact_dir() {
  local task=$1 requested=${2:-$GUI_SANDBOX_ARTIFACT_DIR} base name
  [[ -d $requested && ! -L $requested ]] || die "artifact destination must be an existing directory: $requested"
  base=$(realpath -e -- "$requested") || die 'artifact destination cannot be resolved'
  if [[ ${GUI_SANDBOX_TEST_MODE:-0} != 1 ]]; then
    if [[ $requested == "$GUI_SANDBOX_ARTIFACT_DIR" ]]; then
      [[ $(stat -c '%u:%g' -- "$base") == "0:$GUI_SANDBOX_TARGET_GID" ]] || die 'root artifact directory has unsafe ownership'
    else
      under_root "$base" "$(realpath -e -- "$GUI_SANDBOX_ALLOWED_WORKTREE_ROOT")" || die 'explicit artifact destination must be under allowed worktree root'
      [[ $(stat -c '%u:%g' -- "$base") == "$GUI_SANDBOX_TARGET_UID:$GUI_SANDBOX_TARGET_GID" ]] || die 'explicit artifact destination must be task-user owned'
    fi
  fi
  name="$task-$(date -u +%Y%m%dT%H%M%SZ)-$$"
  local output="$base/$name"
  (umask 077; mkdir -- "$output") || die "artifact directory already exists: $output"
  chmod 0750 "$output"
  chown "$GUI_SANDBOX_TARGET_UID:$GUI_SANDBOX_TARGET_GID" "$output"
  printf '%s\n' "$output"
}

collect_one() {
  local task=$1 requested=${2:-} vmid workspace config output path
  path=$(require_meta "$task")
  vmid=$(meta_get "$task" vmid)
  workspace=$(meta_get "$task" workspace)
  config=$(managed_config "$vmid" "$task") || die "refusing artifact collection for unmanaged VMID $vmid"
  output=$(make_artifact_dir "$task" "$requested")
  jq . "$path" > "$output/task.json"
  printf '%s\n' "$config" > "$output/pct-config.txt"
  if ! guest_exec "$vmid" /bin/sh -c 'for file in /var/log/gui-sandbox/cua-doctor.json /var/log/gui-sandbox/health-report.json /var/log/gui-sandbox/accessibility-tree.json /var/log/gui-sandbox/desktop-state.json /var/log/gui-sandbox/renderer.txt /var/log/gui-sandbox/wayland-info.txt; do if [ -f "$file" ]; then printf "--- %s ---\n" "$file"; cat "$file"; fi; done' > "$output/guest-health.txt" 2>&1; then
    note "guest health logs unavailable for $task"
  fi
  if ! guest_exec "$vmid" journalctl --no-pager -u gui-sandbox-sway.service -u gui-sandbox-cua.service -n 500 > "$output/guest-journal.txt" 2>&1; then
    note "guest journal unavailable for $task"
  fi
  printf '%s\n' "$workspace" > "$output/workspace.txt"
  chown -R "$GUI_SANDBOX_TARGET_UID:$GUI_SANDBOX_TARGET_GID" "$output"
  printf '%s\n' "$output"
}

destroy_one() {
  local task=$1 requested_artifact=${2:-} vmid config status artifact
  safe_task "$task"
  vmid=$(meta_get "$task" vmid)
  config=$(managed_config "$vmid" "$task") || die "refusing destroy: VMID $vmid is not owned by task $task"
  local workspace
  workspace=$(meta_get "$task" workspace)
  printf '%s\n' "$config" | grep -F "mp0: $workspace,mp=/workspace" >/dev/null || die 'refusing destroy: workspace mount changed'
  artifact=$(collect_one "$task" "$requested_artifact")
  status=$("$GUI_SANDBOX_PCT" status "$vmid" 2>/dev/null || true)
  if printf '%s\n' "$status" | grep -Eq 'status: running|running'; then
    "$GUI_SANDBOX_PCT" stop "$vmid" --timeout 60
  fi
  "$GUI_SANDBOX_PCT" destroy "$vmid" --purge 1
  rm -f "$(meta_path "$task")"
  rm -rf -- "${GUI_SANDBOX_SSH_DIR:?}/$task"
  jq -n --arg task "$task" --arg artifact_dir "$artifact" --argjson vmid "$vmid" '{task:$task,vmid:$vmid,state:"destroyed",artifact_dir:$artifact_dir}'
}

cleanup_partial() {
  local task=$1 vmid=$2 config workspace status
  [[ -n $vmid && -n $task ]] || return 0
  numeric "$vmid" || {
    note "refusing partial cleanup with invalid VMID: $vmid"
    return 0
  }
  config=$(config_for "$vmid" 2>/dev/null || true)
  if [[ -z $config ]]; then
    rm -f "$(meta_path "$task")" 2>/dev/null || true
    rm -rf -- "${GUI_SANDBOX_SSH_DIR:?}/$task" 2>/dev/null || true
    return 0
  fi
  workspace=$(jq -r '.workspace // empty' "$(meta_path "$task")" 2>/dev/null || true)
  if ((vmid >= GUI_SANDBOX_FIRST_VMID && vmid <= GUI_SANDBOX_LAST_VMID)) \
    && tag_in_config "$config" "$managed_tag" \
    && tag_in_config "$config" "$task_prefix$task" \
    && [[ -n $workspace ]] \
    && printf '%s\n' "$config" | grep -F "mp0: $workspace,mp=/workspace" >/dev/null; then
    status=$("$GUI_SANDBOX_PCT" status "$vmid" 2>/dev/null || true)
    if printf '%s\n' "$status" | grep -Eq 'status: running|running'; then
      "$GUI_SANDBOX_PCT" stop "$vmid" --timeout 30 || true
    fi
    if ! "$GUI_SANDBOX_PCT" destroy "$vmid" --purge 1; then
      note "refusing partial cleanup after destroy failure: VMID $vmid"
      return 0
    fi
  else
    note "refusing partial cleanup without task ownership proof: VMID $vmid"
    return 0
  fi
  rm -f "$(meta_path "$task")" 2>/dev/null || true
  rm -rf -- "${GUI_SANDBOX_SSH_DIR:?}/$task" 2>/dev/null || true
}

cmd_template_build() {
  local replace=0 arg archive config
  for arg in "$@"; do
    [[ $arg == --replace ]] && replace=1
  done
  if template_current; then
    jq -n --argjson vmid "$GUI_SANDBOX_TEMPLATE_VMID" --arg schema "$GUI_SANDBOX_PROVISION_SCHEMA" '{state:"ready",vmid:$vmid,provisioning_schema:$schema}'
    return 0
  fi
  if vmid_in_use "$GUI_SANDBOX_TEMPLATE_VMID"; then
    [[ $replace == 1 ]] || die "template VMID $GUI_SANDBOX_TEMPLATE_VMID exists but is stale; pass --replace after review"
    config=$(config_for "$GUI_SANDBOX_TEMPLATE_VMID") || die 'cannot inspect stale template'
    tag_in_config "$config" "$managed_tag" || die 'refusing to replace unowned template VMID'
    tag_in_config "$config" "$template_tag" || die 'refusing to replace non-template VMID'
    local status
    status=$("$GUI_SANDBOX_PCT" status "$GUI_SANDBOX_TEMPLATE_VMID" 2>/dev/null || true)
    if printf '%s\n' "$status" | grep -Eq 'status: running|running'; then
      "$GUI_SANDBOX_PCT" stop "$GUI_SANDBOX_TEMPLATE_VMID" --timeout 60
    fi
    "$GUI_SANDBOX_PCT" destroy "$GUI_SANDBOX_TEMPLATE_VMID" --purge 1
  fi
  check_gpu_host
  ensure_storage
  archive=$(template_archive)
  [[ -s $GUI_SANDBOX_CUA_ARCHIVE ]] || die 'pinned CUA archive is unavailable in the host store'
  "$GUI_SANDBOX_PCT" create "$GUI_SANDBOX_TEMPLATE_VMID" "$archive" \
    --ostype ubuntu \
    --hostname gui-sandbox-template \
    --rootfs "$GUI_SANDBOX_STORAGE_ID:$GUI_SANDBOX_ROOTFS_GIB" \
    --cores "$GUI_SANDBOX_CORES" \
    --memory "$GUI_SANDBOX_MEMORY_MIB" \
    --swap 0 \
    --unprivileged 1 \
    --net0 "name=eth0,bridge=$GUI_SANDBOX_BRIDGE,ip=dhcp,type=veth" \
    --tags "$managed_tag;$template_tag;$schema_prefix$GUI_SANDBOX_PROVISION_SCHEMA"
  apply_idmap "$GUI_SANDBOX_TEMPLATE_VMID"
  "$GUI_SANDBOX_PCT" push "$GUI_SANDBOX_TEMPLATE_VMID" "$GUI_SANDBOX_CUA_ARCHIVE" /tmp/cua-driver.tar.gz
  "$GUI_SANDBOX_PCT" push "$GUI_SANDBOX_TEMPLATE_VMID" "$GUI_SANDBOX_GUEST_PROVISION" /tmp/gui-sandbox-guest-provision.sh
  "$GUI_SANDBOX_PCT" start "$GUI_SANDBOX_TEMPLATE_VMID"
  wait_running "$GUI_SANDBOX_TEMPLATE_VMID"
  guest_exec "$GUI_SANDBOX_TEMPLATE_VMID" /bin/bash /tmp/gui-sandbox-guest-provision.sh \
    --schema "$GUI_SANDBOX_PROVISION_SCHEMA" \
    --nvidia-version "$GUI_SANDBOX_NVIDIA_VERSION" \
    --gpu-name "$GUI_SANDBOX_GPU_NAME" \
    --cua-version "$GUI_SANDBOX_CUA_VERSION" \
    --driver-archive /tmp/cua-driver.tar.gz
  "$GUI_SANDBOX_PCT" stop "$GUI_SANDBOX_TEMPLATE_VMID" --timeout 60
  "$GUI_SANDBOX_PCT" template "$GUI_SANDBOX_TEMPLATE_VMID"
  template_current || die 'template failed final schema/tag validation'
  jq -n --argjson vmid "$GUI_SANDBOX_TEMPLATE_VMID" --arg schema "$GUI_SANDBOX_PROVISION_SCHEMA" --arg image "$GUI_SANDBOX_TEMPLATE_IMAGE" '{state:"ready",vmid:$vmid,provisioning_schema:$schema,image:$image}'
}

cmd_create() {
  local task='' repo='' json=0 arg workspace vmid lease key_dir ip known_hosts
  while (($# > 0)); do
    case "$1" in
      --task) task=${2:?missing task}; shift 2 ;;
      --repo) repo=${2:?missing repo}; shift 2 ;;
      --json) json=1; shift ;;
      *) die "unknown create argument: $1" ;;
    esac
  done
  safe_task "$task"
  [[ -n $repo ]] || die '--repo is required'
  if active_task >/dev/null 2>&1; then
    die "one concurrent task allowed; active task: $(active_task)"
  fi
  template_current || die "template VMID $GUI_SANDBOX_TEMPLATE_VMID is missing or stale; run gui-sandbox template build"
  ensure_storage
  workspace=$(validate_worktree "$repo")
  check_gpu_host
  vmid=$(allocate_vmid)
  lease=$(( $(date +%s) + GUI_SANDBOX_LEASE_SECONDS ))
  key_dir=$(create_ssh_material "$task")
  write_meta "$task" creating "$vmid" "$workspace" "$workspace" '' "$lease" "$key_dir/id_ed25519" "$key_dir/known_hosts"
  # shellcheck disable=SC2034
  local cleanup_needed=1
  trap 'if ((cleanup_needed)); then cleanup_partial "$task" "$vmid"; fi' EXIT
  "$GUI_SANDBOX_PCT" clone "$GUI_SANDBOX_TEMPLATE_VMID" "$vmid" \
    --hostname "$task" \
    --full 0 \
    --storage "$GUI_SANDBOX_STORAGE_ID"
  "$GUI_SANDBOX_PCT" set "$vmid" --tags "$managed_tag;$task_prefix$task;$schema_prefix$GUI_SANDBOX_PROVISION_SCHEMA"
  apply_idmap "$vmid"
  set_container_config "$vmid" "$task" "$workspace"
  "$GUI_SANDBOX_PCT" start "$vmid"
  wait_running "$vmid"
  install_guest_ssh_key "$vmid" "$key_dir"
  ip=$(guest_ip "$vmid")
  known_hosts=$(mktemp "$key_dir/known_hosts.XXXXXX")
  "$GUI_SANDBOX_SSH_KEYSCAN" -T 10 -H -t ed25519 "$ip" > "$known_hosts" 2>/dev/null || true
  [[ -s $known_hosts ]] || die "SSH host key scan failed for $ip"
  chmod 0644 "$known_hosts"
  chown "$GUI_SANDBOX_TARGET_UID:$GUI_SANDBOX_TARGET_GID" "$known_hosts"
  mv -f "$known_hosts" "$key_dir/known_hosts"
  ip=$(printf '%s' "$ip" | tr -d '[:space:]')
  local metadata_path metadata_tmp
  metadata_path=$(require_meta "$task")
  metadata_tmp=$(mktemp "$GUI_SANDBOX_TASK_DIR/.${task}.XXXXXX")
  jq --arg ip "$ip" '.ip=$ip | .state="creating"' "$metadata_path" > "$metadata_tmp"
  chmod 0600 "$metadata_tmp"
  chown root:root "$metadata_tmp"
  mv -f "$metadata_tmp" "$metadata_path"
  ssh_task "$task" env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 /bin/true
  guest_exec "$vmid" /bin/bash -c 'test "$(stat -c %u:%g /workspace)" = 1000:1000 && findmnt -no OPTIONS /workspace | grep -Eq "(^|,)nodev(,|$)" && findmnt -no OPTIONS /workspace | grep -Eq "(^|,)nosuid(,|$)"'
  guest_exec "$vmid" runuser -u agent -- env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 /usr/local/bin/gui-sandbox-health
  # shellcheck disable=SC2034
  update_meta "$task" '.state="active" | .health="healthy"'
  # shellcheck disable=SC2034
  cleanup_needed=0
  trap - EXIT
  local result
  result=$(jq . "$(meta_path "$task")")
  if ((json)); then
    jq --arg workspace "$workspace" --arg connection "ssh -i $key_dir/id_ed25519 agent@$ip" '. + {workspace_path:$workspace,ssh_command:$connection,cua_command:"gui-sandbox cua " + .task}' <<< "$result"
  else
    printf '%s\n' "$result"
  fi
}

cmd_status() {
  local task='' json=0 arg path
  for arg in "$@"; do
    if [[ $arg == --json ]]; then json=1; elif [[ -z $task ]]; then task=$arg; else die "unknown status argument: $arg"; fi
  done
  if [[ -n $task ]]; then
    path=$(require_meta "$task")
    if ((json)); then
      jq --argjson now "$(date +%s)" '. + {expired: (.lease_expires < $now)}' "$path"
    else
      jq . "$path"
    fi
    return 0
  fi
  if ((json)); then
    all_meta_paths | xargs -r jq -s --argjson now "$(date +%s)" 'map(. + {expired: (.lease_expires < $now)})'
  else
    all_meta_paths | while IFS= read -r path; do jq -c . "$path"; done
  fi
}

cmd_exec() {
  local task=${1:-} separator=${2:-}
  safe_task "$task"
  [[ $separator == -- ]] || die "exec requires \`--\` before guest argv"
  shift 2
  (($# > 0)) || die 'exec requires guest argv'
  require_meta "$task" >/dev/null
  ssh_task "$task" env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 bash -lc "cd /workspace && exec $(printf '%q ' "$@")"
}

cmd_launch() {
  local task=${1:-} separator=${2:-} quoted command log_path
  safe_task "$task"
  [[ $separator == -- ]] || die 'launch requires `--` before guest argv'
  shift 2
  (($# > 0)) || die 'launch requires guest argv'
  require_meta "$task" >/dev/null
  command=
  for quoted in "$@"; do command+=" $(shell_quote "$quoted")"; done
  log_path="/run/user/1000/gui-sandbox-$task.log"
  ssh_task "$task" env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 bash -lc "cd /workspace && nohup$command >$(shell_quote "$log_path") 2>&1 </dev/null & printf '%s\\n' \$!"
}

cmd_cua() {
  local task=${1:-} tool=${2:-} json=${3:-} extra=${4:-} remote_file result_file artifact_dir host_file suffix
  safe_task "$task"
  [[ $tool =~ ^[A-Za-z0-9_]+$ ]] || die 'invalid CUA tool name'
  [[ -n $json ]] || die 'CUA JSON argument is required'
  jq -e . >/dev/null <<< "$json" || die 'CUA argument is not valid JSON'
  [[ -z $extra ]] || die "unexpected CUA argument: $extra"
  require_meta "$task" >/dev/null
  result_file=$(mktemp "$GUI_SANDBOX_STATE_DIR/.cua-result.XXXXXX")
  suffix=png
  [[ $tool == zoom ]] && suffix=jpg
  remote_file="/run/user/1000/gui-sandbox-$task-$$.$suffix"
  local -a args=(env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 CUA_DRIVER_RS_ENABLE_WAYLAND=1 cua-driver call "$tool" "$json" --socket=/run/user/1000/cua-driver.sock)
  if [[ $tool == get_desktop_state || $tool == zoom ]]; then
    args+=(--screenshot-out-file "$remote_file")
  fi
  if ! ssh_task "$task" "${args[@]}" > "$result_file"; then
    rm -f "$result_file"
    die "CUA call failed: $tool"
  fi
  artifact_dir=$(make_artifact_dir "$task")
  if [[ ( $tool == get_desktop_state || $tool == zoom ) ]] && ssh_task "$task" test -f "$remote_file" >/dev/null 2>&1; then
    host_file="$artifact_dir/$(basename "$remote_file")"
    copy_guest_output "$task" "$remote_file" "$host_file" || die 'failed to copy CUA screenshot'
    ssh_task "$task" rm -f "$remote_file" || true
    if jq -e . "$result_file" >/dev/null 2>&1 && jq -e 'type == "object"' "$result_file" >/dev/null 2>&1; then
      jq --arg path "$host_file" '. + {host_artifact:$path}' "$result_file"
    else
      jq -n --rawfile result "$result_file" --arg path "$host_file" '{result:$result,host_artifact:$path}'
    fi
  else
    cat "$result_file"
  fi
  rm -f "$result_file"
}

cmd_mcp() {
  local task=${1:-} extra=${2:-}
  safe_task "$task"
  [[ -z $extra ]] || die "unexpected mcp argument: $extra"
  require_meta "$task" >/dev/null
  ssh_task "$task" env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 CUA_DRIVER_RS_ENABLE_WAYLAND=1 cua-driver mcp --socket=/run/user/1000/cua-driver.sock
}

cmd_collect() {
  local task=${1:-} dest='' arg
  safe_task "$task"
  shift
  while (($# > 0)); do
    case "$1" in
      --dest) dest=${2:?missing destination}; shift 2 ;;
      *) die "unknown collect argument: $1" ;;
    esac
  done
  require_meta "$task" >/dev/null
  collect_one "$task" "$dest"
}

cmd_destroy() {
  local task=${1:-} dest='' arg
  safe_task "$task"
  shift
  while (($# > 0)); do
    case "$1" in
      --dest) dest=${2:?missing destination}; shift 2 ;;
      *) die "unknown destroy argument: $1" ;;
    esac
  done
  require_meta "$task" >/dev/null
  destroy_one "$task" "$dest"
}

cmd_reap() {
  local now path task expiry state vmid workspace config
  now=$(date +%s)
  while IFS= read -r path; do
    task=$(jq -r '.task' "$path")
    expiry=$(jq -r '.lease_expires' "$path")
    state=$(jq -r '.state' "$path")
    [[ $state == active || $state == creating ]] || continue
    numeric "$expiry" || { note "skipping task with invalid lease: $task"; continue; }
    if ((expiry <= now)); then
      note "reaping expired task $task"
      if [[ $state == active ]]; then
        vmid=$(jq -r '.vmid' "$path")
        workspace=$(jq -r '.workspace // empty' "$path")
        config=$(managed_config "$vmid" "$task" 2>/dev/null || true)
        if [[ -z $config ]] || [[ -z $workspace ]] || ! printf '%s\n' "$config" | grep -F "mp0: $workspace,mp=/workspace" >/dev/null; then
          note "skipping expired task without ownership proof: $task"
          continue
        fi
        destroy_one "$task" ''
      else
        vmid=$(jq -r '.vmid' "$path")
        cleanup_partial "$task" "$vmid"
      fi
    fi
  done < <(all_meta_paths)
}

usage() {
  cat >&2 <<'USAGE'
usage:
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
USAGE
  exit 64
}

if [[ ${GUI_SANDBOX_LIBRARY:-0} != 1 ]]; then
  setup_state
  command=${1:-}
  shift || true

  case "$command" in
    template)
      [[ ${1:-} == build ]] || usage
      shift
      acquire_lock
      cmd_template_build "$@"
      ;;
    create)
      acquire_lock
      cmd_create "$@"
      ;;
    status)
      cmd_status "$@"
      ;;
    exec)
      cmd_exec "$@"
      ;;
    launch)
      cmd_launch "$@"
      ;;
    cua)
      cmd_cua "$@"
      ;;
    mcp)
      cmd_mcp "$@"
      ;;
    collect)
      acquire_lock
      cmd_collect "$@"
      ;;
    destroy)
      acquire_lock
      cmd_destroy "$@"
      ;;
    reap)
      acquire_lock
      cmd_reap "$@"
      ;;
    ''|help|--help|-h)
      usage
      ;;
    *)
      usage
      ;;
  esac
fi
