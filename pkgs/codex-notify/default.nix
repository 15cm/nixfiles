{
  lib,
  jq,
  libnotify,
  hyprland,
  procps,
  tmux,
  notify-lib,
  writeShellApplication,
}:

writeShellApplication {
  name = "codex-notify";
  runtimeInputs = [
    jq
    libnotify
    hyprland
    procps
    tmux
  ];
  excludeShellChecks = [ "SC1091" ];

  text = ''
    # shellcheck source=/dev/null
    source "${notify-lib}/lib/notify-lib.sh"
    ${builtins.readFile ./codex-notify.sh}
  '';
}
