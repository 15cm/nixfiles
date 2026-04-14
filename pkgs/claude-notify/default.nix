{
  lib,
  jq,
  libnotify,
  stdenv,
  terminal-notifier,
  writeShellApplication,
}:

writeShellApplication {
  name = "claude-notify";
  runtimeInputs =
    [ jq ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ libnotify ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [ terminal-notifier ];

  text = ''
    payload="$(cat)"
    transcript_path="$(printf '%s' "$payload" | jq -r '.transcript_path // ""')"

    if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
      message="$(jq -r '
        [.[] | select(.role == "assistant")] | last |
        .content |
        if type == "array" then
          [.[] | select(.type == "text") | .text] | join("")
        else
          .
        end // "Turn complete"
      ' "$transcript_path" | cut -c1-180)"
    else
      message="Turn complete"
    fi

    ${lib.optionalString stdenv.hostPlatform.isDarwin ''
      ${lib.getExe terminal-notifier} -title "Claude" -message "$message" -group "claude-turn" >/dev/null 2>&1
    ''}
    ${lib.optionalString stdenv.hostPlatform.isLinux ''
      ${lib.getExe' libnotify "notify-send"} "Claude" "$message" >/dev/null 2>&1
    ''}
  '';
}
