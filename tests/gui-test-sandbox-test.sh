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
export GUI_SANDBOX_ALLOWED_WORKTREE_ROOT="$test_root/workspaces"
export GUI_SANDBOX_STORAGE_CONFIG="$test_root/storage.cfg"
GUI_SANDBOX_TARGET_UID=$(id -u)
GUI_SANDBOX_TARGET_GID=$(id -g)
export GUI_SANDBOX_TARGET_UID GUI_SANDBOX_TARGET_GID
export GUI_SANDBOX_FIRST_VMID=9100
export GUI_SANDBOX_LAST_VMID=9199
export GUI_SANDBOX_TEMPLATE_VMID=9000
export GUI_SANDBOX_PROVISION_SCHEMA=unit

mkdir -p "$GUI_SANDBOX_ALLOWED_WORKTREE_ROOT" "$GUI_SANDBOX_TASK_DIR" "$GUI_SANDBOX_ARTIFACT_DIR" "$GUI_SANDBOX_SSH_DIR"
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

inside="$GUI_SANDBOX_ALLOWED_WORKTREE_ROOT/inside"
outside="$test_root/outside"
mkdir -p "$inside" "$outside"
git -C "$inside" init --quiet
assert test "$(validate_worktree "$inside")" = "$inside"
ln -s "$outside" "$GUI_SANDBOX_ALLOWED_WORKTREE_ROOT/escape"
if (validate_worktree "$GUI_SANDBOX_ALLOWED_WORKTREE_ROOT/escape"); then
  printf 'unexpected symlink escape acceptance\n' >&2
  exit 1
fi

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

export GUI_SANDBOX_PVE_CONFIG_DIR="$test_root/pve-config"
mkdir -p "$GUI_SANDBOX_PVE_CONFIG_DIR"
printf '%s\n' 'lxc.idmap: u 0 123000 65536' 'tags: gui-sandbox-managed' > "$GUI_SANDBOX_PVE_CONFIG_DIR/9102.conf"
apply_idmap 9102
assert rg -q '^lxc.idmap: u 1000 ' "$GUI_SANDBOX_PVE_CONFIG_DIR/9102.conf"
assert test "$(rg -c '^lxc\.idmap:' "$GUI_SANDBOX_PVE_CONFIG_DIR/9102.conf")" = 6

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

storage_log="$test_root/storage.log"
fake_zfs() {
  case "$1" in
    list) return 1 ;;
    create) printf '%s\n' "$*" >> "$storage_log" ;;
    get) printf 'filesystem\n' ;;
  esac
}
fake_pvesm() {
  case "$1" in
    add) printf '%s\n' "$*" >> "$storage_log" ;;
  esac
}
GUI_SANDBOX_ZFS=fake_zfs GUI_SANDBOX_PVESM=fake_pvesm ensure_storage
assert rg -q '^add zfspool agent-sandbox --pool rpool/proxmox/agent-sandbox --content rootdir --sparse 1$' "$storage_log"

cat > "$GUI_SANDBOX_STORAGE_CONFIG" <<'EOF'
zfspool: agent-sandbox
	pool rpool/proxmox/agent-sandbox
	content rootdir
	sparse 1
EOF
storage_log="$test_root/storage-existing.log"
fake_zfs_existing() {
  case "$1" in
    list) return 0 ;;
    get) printf 'filesystem\n' ;;
  esac
}
GUI_SANDBOX_ZFS=fake_zfs_existing GUI_SANDBOX_PVESM=fake_pvesm ensure_storage
assert test ! -e "$storage_log"

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

printf 'ok: gui-test-sandbox path, tags, lock, stale-template, and reaper safety\n'
