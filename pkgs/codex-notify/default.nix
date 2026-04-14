{
  lib,
  jq,
  libnotify,
  stdenv,
  terminal-notifier,
  writeShellApplication,
}:

writeShellApplication {
  name = "codex-notify";
  runtimeInputs =
    [ jq ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ libnotify ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [ terminal-notifier ];

  text = ''
    payload="$1"
    eventType="$(printf '%s' "$payload" | jq -r '.type // ""')"
    [ "$eventType" = "agent-turn-complete" ] || exit 0

    message="$(printf '%s' "$payload" | jq -r '.["last-assistant-message"] // "Turn complete"')"
    summary="$(printf '%s' "$message" | cut -c1-180)"

    ${lib.optionalString stdenv.hostPlatform.isDarwin ''
      ${lib.getExe terminal-notifier} -title "Codex" -message "$summary" -group "codex-turn" >/dev/null 2>&1
    ''}
    ${lib.optionalString stdenv.hostPlatform.isLinux ''
      ${lib.getExe' libnotify "notify-send"} "Codex" "$summary" >/dev/null 2>&1
    ''}
  '';
}
