#!/usr/bin/env bash

set -euo pipefail

schema=
expected_nvidia_version=
expected_gpu_name=
cua_version=
driver_archive=/tmp/cua-driver.tar.gz

while (($# > 0)); do
  case "$1" in
    --schema)
      schema=${2:?missing schema value}
      shift 2
      ;;
    --nvidia-version)
      expected_nvidia_version=${2:?missing NVIDIA version}
      shift 2
      ;;
    --gpu-name)
      expected_gpu_name=${2:?missing GPU name}
      shift 2
      ;;
    --cua-version)
      cua_version=${2:?missing CUA version}
      shift 2
      ;;
    --driver-archive)
      driver_archive=${2:?missing driver archive}
      shift 2
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      exit 64
      ;;
  esac
done

[[ $schema =~ ^[a-z0-9]+$ ]] || {
  printf 'invalid provisioning schema\n' >&2
  exit 64
}
[[ $expected_nvidia_version =~ ^[0-9]+(\.[0-9]+)+$ ]] || {
  printf 'invalid NVIDIA driver version\n' >&2
  exit 64
}
[[ -n $expected_gpu_name && $expected_gpu_name != *$'\n'* ]] || {
  printf 'invalid GPU name\n' >&2
  exit 64
}
[[ $cua_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  printf 'invalid CUA version\n' >&2
  exit 64
}
[[ -s $driver_archive ]] || {
  printf 'CUA archive missing: %s\n' "$driver_archive" >&2
  exit 74
}

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install --yes --no-install-recommends \
  at-spi2-core \
  ca-certificates \
  curl \
  dbus \
  dbus-user-session \
  dbus-x11 \
  ffmpeg \
  fonts-dejavu \
  fonts-noto-color-emoji \
  fonts-noto-core \
  git \
  jq \
  libx11-6 \
  libxi6 \
  libxkbcommon0 \
  mesa-utils \
  openssh-server \
  pciutils \
  sway \
  sudo \
  vulkan-tools \
  wayland-utils \
  xdg-desktop-portal \
  xdg-desktop-portal-wlr \
  xwayland
apt-get clean
rm -rf /var/lib/apt/lists/*

if ! getent group agent >/dev/null; then
  existing_group=$(getent group 1000 | cut -d: -f1 || true)
  if [[ -n $existing_group ]]; then
    groupmod --new-name agent "$existing_group"
  else
    groupadd --gid 1000 agent
  fi
fi

if ! getent passwd agent >/dev/null; then
  existing_user=$(getent passwd 1000 | cut -d: -f1 || true)
  if [[ -n $existing_user ]]; then
    usermod --login agent --home /home/agent --move-home "$existing_user"
  else
    useradd --create-home --uid 1000 --gid 1000 --shell /bin/bash agent
  fi
fi

user_uid=$(id -u agent)
user_gid=$(id -g agent)
[[ $user_uid == 1000 && $user_gid == 1000 ]] || {
  printf 'agent must remain UID/GID 1000, got %s/%s\n' "$user_uid" "$user_gid" >&2
  exit 78
}

ensure_group() {
  local name=$1 gid=$2
  if ! getent group "$name" >/dev/null; then
    if getent group "$gid" >/dev/null; then
      groupmod --new-name "$name" "$(getent group "$gid" | cut -d: -f1)"
    else
      groupadd --gid "$gid" "$name"
    fi
  fi
  usermod --append --groups "$name" agent
}

ensure_group video 44
ensure_group render 109

passwd --lock agent
usermod --shell /bin/bash agent
install --directory --owner=agent --group=agent --mode=0700 /home/agent/.ssh
rm -f /home/agent/.ssh/authorized_keys
rm -f /root/.ssh/authorized_keys

install --directory --owner=agent --group=agent --mode=0755 \
  /home/agent/.config/sway \
  /home/agent/.config/systemd/user

cat > /home/agent/.config/sway/config <<'SWAY_CONFIG'
set $mod Mod4
output HEADLESS-1 mode 1920x1080
output HEADLESS-1 scale 1
xwayland enable
default_border none
focus_follows_mouse no
workspace_layout tabbed
exec_always dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_RUNTIME_DIR
SWAY_CONFIG
chown agent:agent /home/agent/.config/sway/config
chmod 0644 /home/agent/.config/sway/config

install --directory --owner=root --group=root --mode=0755 /etc/gui-sandbox
printf '%s\n' "$schema" > /etc/gui-sandbox/provisioning-schema
printf '%s\n' "$expected_nvidia_version" > /etc/gui-sandbox/expected-nvidia-driver
printf '%s\n' "$expected_gpu_name" > /etc/gui-sandbox/expected-gpu-name
printf '%s\n' "$cua_version" > /etc/gui-sandbox/cua-driver-version
chmod 0644 /etc/gui-sandbox/*

rm -rf /opt/cua-driver
install --directory --owner=root --group=root --mode=0755 /opt/cua-driver
tar --extract --gzip --file "$driver_archive" --strip-components=1 --directory /opt/cua-driver
test -x /opt/cua-driver/cua-driver
ln -sfn /opt/cua-driver/cua-driver /usr/local/bin/cua-driver
if [[ -x /opt/cua-driver/cua-cursor-theme ]]; then
  ln -sfn /opt/cua-driver/cua-cursor-theme /usr/local/bin/cua-cursor-theme
fi

cat > /etc/profile.d/gui-sandbox.sh <<'PROFILE'
export XDG_RUNTIME_DIR=/run/user/1000
export WAYLAND_DISPLAY=wayland-1
export DISPLAY=:0
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_DESKTOP=sway
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
export CUA_DRIVER_RS_ENABLE_WAYLAND=1
export GTK_MODULES=gail:atk-bridge
export GDK_BACKEND=wayland,x11
export QT_QPA_PLATFORM='wayland;xcb'
export SDL_VIDEODRIVER=wayland
export WLR_RENDERER_ALLOW_SOFTWARE=0
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __EGL_VENDOR_LIBRARY_FILENAMES=/opt/gui-sandbox/host-nvidia/share/glvnd/egl_vendor.d/10_nvidia.json
export LD_LIBRARY_PATH=/opt/gui-sandbox/host-nvidia/lib:/opt/gui-sandbox/host-nvidia-bin/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export LIBGL_DRIVERS_PATH=/opt/gui-sandbox/host-nvidia/lib/dri
PROFILE
chmod 0644 /etc/profile.d/gui-sandbox.sh

install --directory --owner=root --group=root --mode=0755 /etc/xdg/xdg-desktop-portal
cat > /etc/xdg/xdg-desktop-portal/portals.conf <<'PORTALS'
[preferred]
default=wlr
PORTALS
chmod 0644 /etc/xdg/xdg-desktop-portal/portals.conf

cat > /etc/systemd/system/gui-sandbox-sway.service <<'SWAY_UNIT'
[Unit]
Description=GUI test sandbox headless Sway session
After=network-online.target user@1000.service
Wants=network-online.target
Requires=user@1000.service

[Service]
Type=simple
User=agent
Group=agent
Environment=HOME=/home/agent
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
Environment=CUA_DRIVER_RS_ENABLE_WAYLAND=1
Environment=WAYLAND_DISPLAY=wayland-1
Environment=XDG_SESSION_TYPE=wayland
Environment=XDG_CURRENT_DESKTOP=sway
Environment=XDG_SESSION_DESKTOP=sway
Environment=GDK_BACKEND=wayland,x11
Environment=QT_QPA_PLATFORM=wayland;xcb
Environment=GTK_MODULES=gail:atk-bridge
Environment=WLR_BACKENDS=headless
Environment=WLR_HEADLESS_OUTPUTS=1
Environment=WLR_RENDERER=gles2
Environment=WLR_RENDERER_ALLOW_SOFTWARE=0
Environment=WLR_NO_HARDWARE_CURSORS=1
Environment=LIBGL_ALWAYS_SOFTWARE=0
Environment=__GLX_VENDOR_LIBRARY_NAME=nvidia
Environment=__EGL_VENDOR_LIBRARY_FILENAMES=/opt/gui-sandbox/host-nvidia/share/glvnd/egl_vendor.d/10_nvidia.json
Environment=LD_LIBRARY_PATH=/opt/gui-sandbox/host-nvidia/lib:/opt/gui-sandbox/host-nvidia-bin/lib
Environment=LIBGL_DRIVERS_PATH=/opt/gui-sandbox/host-nvidia/lib/dri
ExecStart=/usr/bin/sway --unsupported-gpu --config=/home/agent/.config/sway/config
Restart=always
RestartSec=2
KillMode=mixed
TimeoutStopSec=15

[Install]
WantedBy=multi-user.target
SWAY_UNIT

cat > /etc/systemd/system/gui-sandbox-cua.service <<'CUA_UNIT'
[Unit]
Description=GUI test sandbox CUA Driver daemon
After=gui-sandbox-sway.service
Requires=gui-sandbox-sway.service

[Service]
Type=simple
User=agent
Group=agent
Environment=HOME=/home/agent
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
Environment=CUA_DRIVER_RS_ENABLE_WAYLAND=1
Environment=WAYLAND_DISPLAY=wayland-1
Environment=DISPLAY=:0
Environment=XDG_SESSION_TYPE=wayland
Environment=XDG_CURRENT_DESKTOP=sway
Environment=GTK_MODULES=gail:atk-bridge
Environment=WLR_RENDERER_ALLOW_SOFTWARE=0
Environment=__GLX_VENDOR_LIBRARY_NAME=nvidia
Environment=__EGL_VENDOR_LIBRARY_FILENAMES=/opt/gui-sandbox/host-nvidia/share/glvnd/egl_vendor.d/10_nvidia.json
Environment=LD_LIBRARY_PATH=/opt/gui-sandbox/host-nvidia/lib:/opt/gui-sandbox/host-nvidia-bin/lib
Environment=LIBGL_DRIVERS_PATH=/opt/gui-sandbox/host-nvidia/lib/dri
ExecStart=/usr/local/bin/cua-driver serve --socket=/run/user/1000/cua-driver.sock --permission-mode standard
Restart=always
RestartSec=2
KillMode=mixed
TimeoutStopSec=15

[Install]
WantedBy=multi-user.target
CUA_UNIT

cat > /etc/systemd/system/gui-sandbox-health.service <<'HEALTH_UNIT'
[Unit]
Description=GUI test sandbox health check
After=gui-sandbox-cua.service
Requires=gui-sandbox-cua.service

[Service]
Type=oneshot
User=agent
Group=agent
Environment=HOME=/home/agent
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
Environment=CUA_DRIVER_RS_ENABLE_WAYLAND=1
Environment=WAYLAND_DISPLAY=wayland-1
Environment=DISPLAY=:0
Environment=XDG_SESSION_TYPE=wayland
Environment=XDG_CURRENT_DESKTOP=sway
Environment=GTK_MODULES=gail:atk-bridge
Environment=WLR_RENDERER_ALLOW_SOFTWARE=0
Environment=__GLX_VENDOR_LIBRARY_NAME=nvidia
Environment=__EGL_VENDOR_LIBRARY_FILENAMES=/opt/gui-sandbox/host-nvidia/share/glvnd/egl_vendor.d/10_nvidia.json
Environment=LD_LIBRARY_PATH=/opt/gui-sandbox/host-nvidia/lib:/opt/gui-sandbox/host-nvidia-bin/lib
Environment=LIBGL_DRIVERS_PATH=/opt/gui-sandbox/host-nvidia/lib/dri
ExecStart=/usr/local/bin/gui-sandbox-health
[Install]
WantedBy=multi-user.target
HEALTH_UNIT

cat > /usr/local/bin/gui-sandbox-health <<'HEALTH_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

expected=$(cat /etc/gui-sandbox/expected-nvidia-driver)
expected_gpu=$(cat /etc/gui-sandbox/expected-gpu-name)
runtime=${XDG_RUNTIME_DIR:-/run/user/1000}
wayland=${WAYLAND_DISPLAY:-wayland-1}
export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-unix:path=$runtime/bus}
export CUA_DRIVER_RS_ENABLE_WAYLAND=1
export LD_LIBRARY_PATH=/opt/gui-sandbox/host-nvidia/lib:/opt/gui-sandbox/host-nvidia-bin/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export LIBGL_DRIVERS_PATH=/opt/gui-sandbox/host-nvidia/lib/dri
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __EGL_VENDOR_LIBRARY_FILENAMES=/opt/gui-sandbox/host-nvidia/share/glvnd/egl_vendor.d/10_nvidia.json
[[ -S "$runtime/$wayland" ]] || { echo "missing Wayland socket" >&2; exit 1; }
[[ -S /run/user/1000/cua-driver.sock ]] || { echo "missing CUA socket" >&2; exit 1; }

if command -v wayland-info >/dev/null 2>&1; then
  wayland-info >/var/log/gui-sandbox/wayland-info.txt
fi

if [[ -S /tmp/.X11-unix/X0 ]]; then
  export DISPLAY=:0
elif [[ -S /tmp/.X11-unix/X1 ]]; then
  export DISPLAY=:1
fi

renderer=
if command -v glxinfo >/dev/null 2>&1; then
  renderer=$(glxinfo -B 2>/dev/null || true)
fi
if [[ -z $renderer ]] && command -v eglinfo >/dev/null 2>&1; then
  renderer=$(eglinfo -B 2>/dev/null || true)
fi
printf '%s\n' "$renderer" > /var/log/gui-sandbox/renderer.txt
[[ -n $renderer ]] || { echo "GPU probe produced no renderer" >&2; exit 1; }
if printf '%s\n' "$renderer" | grep -Eiq 'llvmpipe|softpipe|software rasterizer|swiftshader'; then
  echo "software renderer detected" >&2
  exit 1
fi
printf '%s\n' "$renderer" | grep -Fqi -- "$expected_gpu" || {
  echo "renderer is not $expected_gpu" >&2
  exit 1
}
printf '%s\n' "$renderer" | grep -F "$expected" >/dev/null || {
  echo "renderer driver does not match host $expected" >&2
  exit 1
}

if command -v gdbus >/dev/null 2>&1; then
  gdbus introspect --session --dest org.a11y.Bus --object-path /org/a11y/bus >/dev/null
fi

doctor_json=$(/usr/local/bin/cua-driver doctor --json)
printf '%s\n' "$doctor_json" > /var/log/gui-sandbox/cua-doctor.json
jq -e '.ok == true and any(.probes[]; .label == "display server" and .status == "ok") and any(.probes[]; .label == "AT-SPI" and .status == "ok")' \
  /var/log/gui-sandbox/cua-doctor.json >/dev/null
/usr/local/bin/cua-driver call health_report '{}' --socket=/run/user/1000/cua-driver.sock > /var/log/gui-sandbox/health-report.json
jq -e '.overall == "ok"' /var/log/gui-sandbox/health-report.json >/dev/null
/usr/local/bin/cua-driver call get_accessibility_tree '{}' --socket=/run/user/1000/cua-driver.sock > /var/log/gui-sandbox/accessibility-tree.json
jq -e 'type == "object"' /var/log/gui-sandbox/accessibility-tree.json >/dev/null
/usr/local/bin/cua-driver call get_desktop_state '{}' \
  --screenshot-out-file /var/log/gui-sandbox/health-screenshot.png \
  --socket=/run/user/1000/cua-driver.sock > /var/log/gui-sandbox/desktop-state.json
jq -e 'type == "object"' /var/log/gui-sandbox/desktop-state.json >/dev/null
test -s /var/log/gui-sandbox/health-screenshot.png
HEALTH_SCRIPT
chmod 0755 /usr/local/bin/gui-sandbox-health

cat > /etc/ssh/sshd_config.d/gui-sandbox.conf <<'SSH_CONFIG'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
AllowUsers agent
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no
SSH_CONFIG
chmod 0644 /etc/ssh/sshd_config.d/gui-sandbox.conf

install --directory --owner=agent --group=agent --mode=0755 /var/log/gui-sandbox
install --directory --owner=root --group=root --mode=0755 /var/lib/systemd/linger
loginctl enable-linger agent || touch /var/lib/systemd/linger/agent
chown agent:agent /var/lib/systemd/linger/agent

systemctl daemon-reload
systemctl enable ssh.service gui-sandbox-sway.service gui-sandbox-cua.service gui-sandbox-health.service
systemctl disable gui-sandbox-health.service || true
systemctl stop gui-sandbox-health.service gui-sandbox-cua.service gui-sandbox-sway.service || true

rm -f /etc/ssh/ssh_host_* /tmp/cua-driver.tar.gz

printf 'gui sandbox guest provisioned: schema=%s cua=%s nvidia=%s gpu=%s\n' \
  "$schema" "$cua_version" "$expected_nvidia_version" "$expected_gpu_name"
