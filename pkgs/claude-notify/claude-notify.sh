payload="$(cat)"
event="$(printf '%s' "$payload" | jq -r '.hook_event_name // ""')"

if [ "$event" = "Stop" ]; then
  title="Claude"
  message="$(printf '%s' "$payload" | jq -r '.last_assistant_message // ""' | cut -c1-180)"
else
  title="Claude - $(printf '%s' "$payload" | jq -r '.title // "Notification"')"
  message="$(printf '%s' "$payload" | jq -r '.message // ""' | cut -c1-180)"
fi

[ -z "$message" ] && exit 0

capture_tmux_info
find_hypr_window
send_notify "claude-notify" "$title" "$message"
