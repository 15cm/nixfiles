{
  lib,
  jq,
  libnotify,
  hyprland,
  procps,
  tmux,
  writeShellApplication,
}:

writeShellApplication {
  name = "claude-notify";
  runtimeInputs = [
    jq
    libnotify
    hyprland
    procps
    tmux
  ];

  text = builtins.readFile ./claude-notify.sh;
}
