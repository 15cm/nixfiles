#!/usr/bin/env bash
payload="$(cat)"
event="$(printf '%s' "$payload" | jq -r '.hook_event_name // ""')"
session_id="$(printf '%s' "$payload" | jq -r '.session_id // ""')"

logfile="/tmp/claude-notify-${session_id:-unknown}.log"
log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >> "$logfile"; }

log "event=$event session_id=$session_id pid=$$ TMUX=${TMUX:-} DISPLAY=${DISPLAY:-} WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}"

if [ "$event" = "Stop" ]; then
  title="Claude"
  message="$(printf '%s' "$payload" | jq -r '.last_assistant_message // ""' | cut -c1-180)"
else
  title="Claude - $(printf '%s' "$payload" | jq -r '.title // "Notification"')"
  message="$(printf '%s' "$payload" | jq -r '.message // ""' | cut -c1-180)"
fi

log "title=$title message=$message"
[ -z "$message" ] && { log "empty message, exit"; exit 0; }

# Find ancestor hyprland window.
# tmux server daemonizes (re-parent to PID 1), breaking the normal process
# tree walk — start from the tmux client PID instead.
addr=""
if clients=$(hyprctl clients -j 2>/dev/null) && [ -n "$clients" ]; then
  if [ -n "${TMUX:-}" ]; then
    pid=$(tmux display-message -p "#{client_pid}" 2>/dev/null | tr -d ' ' || true)
    log "tmux client_pid=$pid"
  fi
  pid="${pid:-$$}"
  log "starting pid walk from pid=$pid"
  while [ "$pid" -gt 1 ]; do
    found=$(printf '%s' "$clients" | jq -r --argjson pid "$pid" \
      '.[] | select(.pid == $pid) | .address' 2>/dev/null | head -1)
    if [ -n "$found" ]; then
      addr="$found"
      log "found window addr=$addr at pid=$pid"
      break
    fi
    ppid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    log "pid=$pid not found, ppid=$ppid"
    pid="$ppid"
    [ -z "$pid" ] && break
  done
else
  log "hyprctl clients failed or empty"
fi
# Fallback: active window at hook time
if [ -z "$addr" ]; then
  addr=$(hyprctl activewindow -j 2>/dev/null | jq -r '.address // ""' 2>/dev/null || true)
  log "fallback activewindow addr=$addr"
fi

log "final addr=$addr, sending notification"

# Action key is the hyprctl command itself (eval'd on receive).
# Colon in "address:$addr" would be misread as key:label separator,
# so pass addr as a plain arg and let the action string reconstruct it.
focus_action=""
[ -n "$addr" ] && focus_action="hyprctl dispatch focuswindow address $addr"

(
  action=$(notify-send --wait \
    --app-name="claude-notify" \
    ${focus_action:+--action="$focus_action"} \
    "$title" "$message" 2>/dev/null || true)
  log "action=$action"
  log "to focus manually: hyprctl dispatch focuswindow address:$addr"
  if [ -n "$action" ]; then
    log "exec: $action"
    eval "$action" >> "$logfile" 2>&1
  fi
) &
disown
