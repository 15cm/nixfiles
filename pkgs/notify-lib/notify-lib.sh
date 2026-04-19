# notify-lib.sh — shared notification helpers (source this file, do not execute)
# Requires: jq, hyprctl, tmux, notify-send in PATH

# capture_tmux_info
# Reads TMUX_PANE from environment.
# Sets: _NOTIFY_TMUX_PANE, _NOTIFY_TMUX_SESSION, _NOTIFY_TMUX_WINDOW
capture_tmux_info() {
  _NOTIFY_TMUX_PANE="${TMUX_PANE:-}"
  _NOTIFY_TMUX_SESSION=""
  _NOTIFY_TMUX_WINDOW=""
  if [ -n "$_NOTIFY_TMUX_PANE" ]; then
    _NOTIFY_TMUX_SESSION=$(tmux display-message -p -t "$_NOTIFY_TMUX_PANE" '#{session_name}')
    _NOTIFY_TMUX_WINDOW=$(tmux display-message -p -t "$_NOTIFY_TMUX_PANE" '#{window_index}')
  fi
}

# find_hypr_window
# Walks process tree to find ancestor Hyprland window.
# tmux server daemonizes (re-parents to PID 1), so start from tmux client PID.
# Sets: _NOTIFY_HYPR_ADDR
find_hypr_window() {
  _NOTIFY_HYPR_ADDR=""
  local clients pid found ppid
  clients=""
  pid=""
  if clients=$(hyprctl clients -j 2>/dev/null) && [ -n "$clients" ]; then
    if [ -n "${TMUX:-}" ]; then
      pid=$(tmux display-message -p "#{client_pid}" 2>/dev/null | tr -d ' ' || true)
    fi
    pid="${pid:-$$}"
    while [ "$pid" -gt 1 ]; do
      found=$(printf '%s' "$clients" | jq -r --argjson pid "$pid" \
        '.[] | select(.pid == $pid) | .address' 2>/dev/null | head -1)
      if [ -n "$found" ]; then
        _NOTIFY_HYPR_ADDR="$found"
        break
      fi
      ppid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
      pid="$ppid"
      [ -z "$pid" ] && break
    done
  fi
  # Fallback: active window at hook time
  if [ -z "$_NOTIFY_HYPR_ADDR" ]; then
    _NOTIFY_HYPR_ADDR=$(hyprctl activewindow -j 2>/dev/null | jq -r '.address // ""' 2>/dev/null || true)
  fi
}

# send_notify APP_NAME TITLE MESSAGE
# Uses globals: _NOTIFY_HYPR_ADDR, _NOTIFY_TMUX_PANE, _NOTIFY_TMUX_SESSION, _NOTIFY_TMUX_WINDOW
# Sends desktop notification; if Focus action clicked, switches to originating window/pane.
send_notify() {
  local app_name="$1" title="$2" message="$3"
  local addr="$_NOTIFY_HYPR_ADDR"
  local tmux_pane="$_NOTIFY_TMUX_PANE"
  local tmux_session="$_NOTIFY_TMUX_SESSION"
  local tmux_window="$_NOTIFY_TMUX_WINDOW"
  (
    local action
    if [ -n "$addr" ]; then
      action=$(
        notify-send --wait \
          --app-name="$app_name" \
          --action=default=Focus \
          "$title" "$message"
      )
    else
      action=$(
        notify-send --wait \
          --app-name="$app_name" \
          "$title" "$message"
      )
    fi
    if [ "$action" = "default" ] && [ -n "$addr" ]; then
      hyprctl dispatch focuswindow "address:$addr" 2>/dev/null
      if [ -n "$tmux_pane" ]; then
        tmux switch-client -t "$tmux_session"
        tmux select-window -t "${tmux_session}:${tmux_window}"
        tmux select-pane -t "$tmux_pane"
      fi
    fi
  ) &
  disown
}
