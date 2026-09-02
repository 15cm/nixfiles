#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cli="$repo_root/hosts/modules/services/gui-test-sandbox/gui-sandbox.sh"
fake_pct="$repo_root/tests/fake-pct.sh"
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

export GUI_SANDBOX_NO_SUDO=1
export GUI_SANDBOX_LIBRARY=1
export GUI_SANDBOX_TEST_MODE=1
export GUI_SANDBOX_STATE_DIR="$test_root/state"
export GUI_SANDBOX_TASK_DIR="$GUI_SANDBOX_STATE_DIR/tasks"
export GUI_SANDBOX_ARTIFACT_DIR="$GUI_SANDBOX_STATE_DIR/artifacts"
export GUI_SANDBOX_SSH_DIR="$GUI_SANDBOX_STATE_DIR/ssh"
export GUI_SANDBOX_LOCK_FILE="$GUI_SANDBOX_STATE_DIR/lock"
export GUI_SANDBOX_STORAGE_CONFIG="$test_root/storage.cfg"
export GUI_SANDBOX_STORAGE_MOUNTPOINT="$test_root/storage-mount"
export GUI_SANDBOX_ROOTFS_MOUNT="$test_root/rootfs-mount"
GUI_SANDBOX_TARGET_UID=$(id -u)
GUI_SANDBOX_TARGET_GID=$(id -g)
export GUI_SANDBOX_TARGET_UID GUI_SANDBOX_TARGET_GID
export GUI_SANDBOX_FIRST_VMID=9100
export GUI_SANDBOX_LAST_VMID=9199
export GUI_SANDBOX_TEMPLATE_VMID=9000
export GUI_SANDBOX_PROVISION_SCHEMA=unit

mkdir -p "$GUI_SANDBOX_TASK_DIR" "$GUI_SANDBOX_ARTIFACT_DIR" "$GUI_SANDBOX_SSH_DIR"
# shellcheck disable=SC1090
source "$cli"

assert() {
  if ! "$@"; then
    printf 'not ok: %s\n' "$*" >&2
    exit 1
  fi
}

assert_not() {
  if "$@"; then
    printf 'unexpected success: %s\n' "$*" >&2
    exit 1
  fi
}

run0_log="$test_root/run0.log"
fake_run0="$test_root/run0"
# shellcheck disable=SC2016
printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\n" "$*" > "$GUI_SANDBOX_RUN0_LOG"' 'printf "run0-ok\n"' > "$fake_run0"
chmod 0755 "$fake_run0"
run0_result=$(env \
  GUI_SANDBOX_NO_SUDO=0 \
  GUI_SANDBOX_FORCE_NO_NEW_PRIVS=1 \
  GUI_SANDBOX_RUN0="$fake_run0" \
  GUI_SANDBOX_RUN0_LOG="$run0_log" \
  bash "$cli" status --json)
assert test "$run0_result" = run0-ok
assert rg -q -- '--user=root --pipe /run/current-system/sw/bin/gui-sandbox status --json' "$run0_log"

outside="$test_root/outside"
inside="$test_root/inside"
mkdir -p "$inside" "$outside"
git -C "$inside" init --quiet
assert test "$(validate_worktree "$inside")" = "$inside"
git -C "$outside" init --quiet
assert test "$(validate_worktree "$outside")" = "$outside"

assert tag_in_config $'tags: gui-sandbox-managed;gui-sandbox-task-demo' gui-sandbox-managed
assert_not tag_in_config $'tags: gui-sandbox-unmanaged' gui-sandbox-managed

expected_idmap=$(printf 'lxc.idmap: u 0 %s 1000\nlxc.idmap: u 1000 %s 1\nlxc.idmap: u 1001 %s 64535\nlxc.idmap: g 0 %s 1000\nlxc.idmap: g 1000 %s 1\nlxc.idmap: g 1001 %s 64535' \
  "$GUI_SANDBOX_SUBID_START" "$GUI_SANDBOX_TARGET_UID" "$((GUI_SANDBOX_SUBID_START + 1001))" \
  "$GUI_SANDBOX_SUBID_START" "$GUI_SANDBOX_TARGET_GID" "$((GUI_SANDBOX_SUBID_START + 1001))")
assert test "$(idmap_lines)" = "$expected_idmap"

config_for() {
  case "$1" in
    9000) printf '%s\n' 'template: 1' 'tags: gui-sandbox-managed;gui-sandbox-template;gui-sandbox-schema-unit' ;;
    9100) printf '%s\n' 'tags: gui-sandbox-managed;gui-sandbox-task-expired' "mp0: $inside,mp=/workspace,backup=0,mountoptions=nodev;nosuid" ;;
    9101) printf '%s\n' 'tags: gui-sandbox-task-unmanaged' "mp0: $inside,mp=/workspace,backup=0,mountoptions=nodev;nosuid" ;;
    9102) cat "$GUI_SANDBOX_PVE_CONFIG_DIR/9102.conf" ;;
    *) return 1 ;;
  esac
}
vmid_in_use() {
  [[ $1 == 9000 || $1 == 9100 || $1 == 9101 ]]
}
vmid_in_use 9000

export GUI_SANDBOX_PVE_CONFIG_DIR="$test_root/pve-config"
mkdir -p "$GUI_SANDBOX_PVE_CONFIG_DIR"
printf '%s\n' 'lxc.idmap: u 0 123000 65536' 'tags: gui-sandbox-managed' > "$GUI_SANDBOX_PVE_CONFIG_DIR/9102.conf"
apply_idmap 9102
assert rg -q '^lxc.idmap: u 1000 ' "$GUI_SANDBOX_PVE_CONFIG_DIR/9102.conf"
assert test "$(rg -c '^lxc\.idmap:' "$GUI_SANDBOX_PVE_CONFIG_DIR/9102.conf")" = 6
apply_rootfs_mount 9102
assert rg -q "^lxc\.rootfs\.mount = $GUI_SANDBOX_ROOTFS_MOUNT/9102$" "$GUI_SANDBOX_PVE_CONFIG_DIR/9102.conf"

assert template_current
export GUI_SANDBOX_TEMPLATE_VMID=9000
export GUI_SANDBOX_TEMPLATE_IMAGE=unit
export GUI_SANDBOX_TEMPLATE_SHA512=unit

exec {lock_fd}>"$GUI_SANDBOX_LOCK_FILE"
flock -n "$lock_fd"
# shellcheck disable=SC2016
assert_not bash -c 'exec 9>"$1"; flock -n 9' bash "$GUI_SANDBOX_LOCK_FILE"
eval "exec ${lock_fd}>&-"

fake_root="$test_root/fake-pve"
fake_log="$test_root/fake-pct.log"
mkdir -p "$fake_root"
printf 'tags: gui-sandbox-managed;gui-sandbox-task-expired\nmp0: %s,mp=/workspace,backup=0,mountoptions=nodev;nosuid\n' "$inside" > "$fake_root/9100.conf"
printf 'status: stopped\n' > "$fake_root/9100.status"
printf 'tags: gui-sandbox-task-unmanaged\nmp0: %s,mp=/workspace,backup=0,mountoptions=nodev;nosuid\n' "$inside" > "$fake_root/9101.conf"
printf 'status: stopped\n' > "$fake_root/9101.status"
printf 'tags: gui-sandbox-managed;gui-sandbox-task-creating\nmp0: %s,mp=/workspace,backup=0,mountoptions=nodev;nosuid\n' "$inside" > "$fake_root/9102.conf"
printf 'status: stopped\n' > "$fake_root/9102.status"
export FAKE_PCT_ROOT="$fake_root"
export FAKE_PCT_LOG="$fake_log"
export GUI_SANDBOX_PCT="$fake_pct"

write_task() {
  local task=$1 vmid=$2 expires=$3
  jq -n --arg task "$task" --argjson vmid "$vmid" --arg workspace "$inside" --argjson lease_expires "$expires" \
    '{task:$task,state:"active",vmid:$vmid,workspace:$workspace,repo:$workspace,ip:"192.0.2.10",lease_expires:$lease_expires,ssh_key:"",known_hosts:"",provisioning_schema:"unit",gpu:"test"}' \
    > "$GUI_SANDBOX_TASK_DIR/$task.json"
}

fake_ssh_log="$test_root/fake-ssh.log"
fake_ssh() {
  printf '%s\n' "$*" >> "$fake_ssh_log"
  [[ ${*: -1} != -- ]]
}
mkdir -p "$GUI_SANDBOX_SSH_DIR/sshcheck"
touch "$GUI_SANDBOX_SSH_DIR/sshcheck/id_ed25519" "$GUI_SANDBOX_SSH_DIR/sshcheck/known_hosts"
write_task sshcheck 9100 9999999999
GUI_SANDBOX_SSH=fake_ssh ssh_task sshcheck env XDG_RUNTIME_DIR=/run/user/1000 /bin/true
assert_not rg -q '(^| )--($| )' "$fake_ssh_log"

mkdir -p "$GUI_SANDBOX_SSH_DIR/env"
touch "$GUI_SANDBOX_SSH_DIR/env/id_ed25519" "$GUI_SANDBOX_SSH_DIR/env/known_hosts"
write_task env 9100 9999999999
GUI_SANDBOX_SSH=fake_ssh ssh_task env env XDG_RUNTIME_DIR=/run/user/1000 /bin/true
assert rg -q "'env' 'XDG_RUNTIME_DIR=/run/user/1000' '/bin/true'" "$fake_ssh_log"

write_task expired 9100 1
GUI_SANDBOX_LIBRARY=0 bash "$cli" reap >/dev/null
assert test ! -e "$fake_root/9100.conf"
assert rg -q '^destroy 9100 ' "$fake_log"

write_task unmanaged 9101 1
env GUI_SANDBOX_LIBRARY=0 bash "$cli" reap >/dev/null
assert test -e "$fake_root/9101.conf"
assert_not rg -q '^destroy 9101 ' "$fake_log"

write_task creating 9102 1
jq '.state="creating"' "$GUI_SANDBOX_TASK_DIR/creating.json" > "$GUI_SANDBOX_TASK_DIR/creating.tmp"
mv "$GUI_SANDBOX_TASK_DIR/creating.tmp" "$GUI_SANDBOX_TASK_DIR/creating.json"
GUI_SANDBOX_LIBRARY=0 bash "$cli" reap >/dev/null
assert test ! -e "$fake_root/9102.conf"
assert test ! -e "$GUI_SANDBOX_TASK_DIR/creating.json"

printf 'hostname: creating-destroy\ntags: gui-sandbox-managed;gui-sandbox-task-creating-destroy\n' > "$fake_root/9102.conf"
printf 'status: stopped\n' > "$fake_root/9102.status"
write_task creating-destroy 9102 9999999999
jq '.state="creating"' "$GUI_SANDBOX_TASK_DIR/creating-destroy.json" > "$GUI_SANDBOX_TASK_DIR/creating-destroy.tmp"
mv "$GUI_SANDBOX_TASK_DIR/creating-destroy.tmp" "$GUI_SANDBOX_TASK_DIR/creating-destroy.json"
destroy_result=$(GUI_SANDBOX_LIBRARY=0 bash "$cli" destroy creating-destroy)
assert jq -e '.state == "destroyed" and .vmid == 9102' <<< "$destroy_result"
assert test ! -e "$fake_root/9102.conf"
assert test ! -e "$GUI_SANDBOX_TASK_DIR/creating-destroy.json"

storage_log="$test_root/storage.log"
fake_zfs() {
  case "$1" in
    list) return 1 ;;
    create) printf '%s\n' "$*" >> "$storage_log" ;;
    get)
      case "$5" in
        type) printf 'filesystem\n' ;;
        mountpoint) printf '%s\n' "$GUI_SANDBOX_STORAGE_MOUNTPOINT" ;;
        mounted) printf 'yes\n' ;;
      esac
      ;;
  esac
}
fake_pvesm() {
  case "$1" in
    add|set) printf '%s\n' "$*" >> "$storage_log" ;;
  esac
}
GUI_SANDBOX_ZFS=fake_zfs GUI_SANDBOX_PVESM=fake_pvesm ensure_storage
assert rg -q "^create -p -o mountpoint=$GUI_SANDBOX_STORAGE_MOUNTPOINT rpool/proxmox/agent-sandbox$" "$storage_log"
assert rg -q "^add zfspool agent-sandbox --pool rpool/proxmox/agent-sandbox --content rootdir --sparse 1 --mountpoint $GUI_SANDBOX_STORAGE_MOUNTPOINT$" "$storage_log"

cat > "$GUI_SANDBOX_STORAGE_CONFIG" <<EOF
zfspool: agent-sandbox
	pool rpool/proxmox/agent-sandbox
	content rootdir
	sparse 1
	mountpoint $GUI_SANDBOX_STORAGE_MOUNTPOINT
EOF
storage_log="$test_root/storage-existing.log"
fake_zfs_existing() {
  case "$1" in
    list) return 0 ;;
    get)
      case "$5" in
        type) printf 'filesystem\n' ;;
        mountpoint) printf '%s\n' "$GUI_SANDBOX_STORAGE_MOUNTPOINT" ;;
        mounted) printf 'yes\n' ;;
      esac
      ;;
  esac
}
GUI_SANDBOX_ZFS=fake_zfs_existing GUI_SANDBOX_PVESM=fake_pvesm ensure_storage
assert test ! -e "$storage_log"

cat > "$GUI_SANDBOX_STORAGE_CONFIG" <<'EOF'
zfspool: agent-sandbox
	pool rpool/proxmox/agent-sandbox
	content rootdir
	sparse 1
	mountpoint //rpool
EOF
storage_log="$test_root/storage-repair.log"
GUI_SANDBOX_ZFS=fake_zfs_existing GUI_SANDBOX_PVESM=fake_pvesm ensure_storage
assert rg -q "^set agent-sandbox --mountpoint $GUI_SANDBOX_STORAGE_MOUNTPOINT$" "$storage_log"

cat > "$GUI_SANDBOX_STORAGE_CONFIG" <<'EOF'
zfspool: agent-sandbox
	pool rpool/proxmox/wrong-pool
EOF
if (GUI_SANDBOX_ZFS=fake_zfs_existing GUI_SANDBOX_PVESM=fake_pvesm ensure_storage); then
  printf 'unexpected storage pool acceptance\n' >&2
  exit 1
fi

fake_cua_ssh() {
  local remote_command=${!#}
  case "$remote_command" in
    *'test -f'*) return 0 ;;
    *cat*) printf 'fake-png-data' ;;
    *'cua-driver call'*) printf '{"ok":true}\n' ;;
  esac
}
mkdir -p "$GUI_SANDBOX_SSH_DIR/cua"
touch "$GUI_SANDBOX_SSH_DIR/cua/id_ed25519" "$GUI_SANDBOX_SSH_DIR/cua/known_hosts"
write_task cua 9100 9999999999
cua_result=$(GUI_SANDBOX_SSH=fake_cua_ssh cmd_cua cua get_desktop_state '{}')
cua_artifact=$(jq -r '.host_artifact' <<< "$cua_result")
assert test -s "$cua_artifact"
assert test "$(stat -c '%u:%g' "$cua_artifact")" = "$GUI_SANDBOX_TARGET_UID:$GUI_SANDBOX_TARGET_GID"

# Multiple active tasks use independent metadata and VMIDs. Stub only the
# guest lifecycle so this exercises the real create state machine safely.
write_task first 9100 9999999999
template_current() { return 0; }
ensure_storage() { :; }
check_gpu_host() { :; }
vmid_in_use() {
  case "$1" in
    9000|9100) return 0 ;;
    *) return 1 ;;
  esac
}
create_ssh_material() {
  local task=$1 dir="$GUI_SANDBOX_SSH_DIR/$1"
  mkdir -p "$dir"
  touch "$dir/id_ed25519" "$dir/id_ed25519.pub"
  printf '%s\n' "$dir"
}
pct_command() { :; }
apply_idmap() { :; }
set_container_config() { :; }
wait_running() { :; }
install_guest_ssh_key() { :; }
guest_ip() { printf '192.0.2.11\n'; }
fake_keyscan() { printf '[192.0.2.11]:22 ssh-ed25519 test-key\n'; }
ssh_task() { :; }
guest_exec() { :; }
wait_guest_gui() { :; }
run_guest_health() { :; }
GUI_SANDBOX_SSH_KEYSCAN=fake_keyscan
export GUI_SANDBOX_SSH_KEYSCAN

second_result=$(cmd_create --task second --repo "$inside" --json)
assert jq -e '.task == "second" and .state == "active" and .health == "healthy" and .vmid == 9101' <<< "$second_result"
assert jq -e '.state == "active" and .vmid == 9100' "$GUI_SANDBOX_TASK_DIR/first.json"
if (cmd_create --task second --repo "$inside" >/dev/null 2>"$test_root/duplicate-task.err"); then
  printf 'unexpected duplicate task acceptance\n' >&2
  exit 1
fi
assert rg -q 'task already exists: second' "$test_root/duplicate-task.err"

printf 'ok: gui-test-sandbox path, tags, lock, stale-template, and reaper safety\n'
