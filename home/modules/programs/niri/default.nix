{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.programs.niri;
  # HM KDL generator emits attr names verbatim. Quote names containing spaces.
  monitorName = monitor: ''"${removePrefix "desc:" monitor.output}"'';
  outputSettings = mapAttrs'
    (name: monitor: nameValuePair "output ${monitorName monitor}" {
      scale = config.my.display.scale;
      "position x=${toString (if name == "one" then 0 else 1920)} y=0" = { };
    }) config.my.display.monitors;
  screenshotDir = "${config.home.homeDirectory}/Screenshots";
  noctalia = lib.getExe config.programs.noctalia.package;
  screenshot = command: "mkdir -p ${escapeShellArg screenshotDir}; ${command} ${screenshotDir}/$(date +%Y-%m-%d-%H%M%S.png)";
  focusOrLaunchOrca = pkgs.writeShellScript "focus-or-launch-orca" ''
    set -eu
    window_id="$(${pkgs.jq}/bin/jq -r '.[] | select((."app-id" // "") == "orca" or (."app-id" // "") == "orca-ide") | .id' < <(${pkgs.niri}/bin/niri msg --json windows) | head -n 1)"
    if [ -n "$window_id" ]; then
      exec ${pkgs.niri}/bin/niri msg action focus-window --id "$window_id"
    fi
    exec ${pkgs.orca-ide}/bin/orca-ide open
  '';
  openWindowInColumn = pkgs.writeShellScript "niri-open-window-in-column" ''
    set -euo pipefail

    niri=${escapeShellArg (lib.getExe pkgs.niri)}
    jq=${escapeShellArg (lib.getExe pkgs.jq)}
    known_ids=[]

    if [ "$#" -eq 0 ]; then
      echo "usage: niri-open-window-in-column COMMAND [ARGUMENT... ]" >&2
      exit 64
    fi

    # Subscribe before spawning so window-open event cannot race the command.
    exec {event_fd}< <("$niri" msg --json event-stream)

    # Event stream starts with a complete state snapshot. Ignore those windows.
    while IFS= read -r event <&"$event_fd"; do
      if "$jq" -e 'has("WindowsChanged")' <<<"$event" >/dev/null; then
        known_ids="$("$jq" -c '.WindowsChanged.windows | map(.id)' <<<"$event")"
        break
      fi
    done

    "$@" &
    child_pid=$!

    while IFS= read -r event <&"$event_fd"; do
      window_id="$("$jq" -r --argjson known_ids "$known_ids" '
        .WindowOpenedOrChanged.window as $window
        | select($window != null)
        | select(($known_ids | index($window.id)) == null)
        | $window.id
      ' <<<"$event")"

      if [ -n "$window_id" ]; then
        "$niri" msg action consume-or-expel-window-left --id "$window_id"
        exit 0
      fi

      if ! kill -0 "$child_pid" 2>/dev/null; then
        wait "$child_pid"
        exit 1
      fi
    done

    wait "$child_pid"
  '';
in
{
  options.my.programs.niri = {
    enable = mkEnableOption "Niri";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.wlr-which-key ];
    home.sessionVariables = {
      XDG_SESSION_TYPE = "wayland";
      QT_QPA_PLATFORM = "wayland;xcb";
    };
    my.env = {
      QT_SCREEN_SCALE_FACTORS = toString config.my.display.scale;
      GDK_SCALE = toString config.my.display.scale;
      GDK_DPI_SCALE = toString (1.0 / config.my.display.scale);
    };

    wayland.windowManager.niri = {
      enable = true;
      package = pkgs.niri;
      systemd.enable = false;
      portalPackage = null;
      settings = {
        prefer-no-csd = true;
        hotkey-overlay.skip-at-startup = true;
        input = {
          keyboard = { repeat-rate = 20; repeat-delay = 200; };
          mouse.accel-profile = "flat";
          mouse.accel-speed = 0.5;
          touchpad = {
            tap = { };
            click-method = "clickfinger";
            natural-scroll = { };
          };
        };
        cursor = {
          xcursor-theme = "breeze_cursors";
          xcursor-size = config.my.display.cursorSize;
          hide-when-typing = true;
          hide-after-inactive-ms = 20000;
        };
        layout = {
          gaps = 5;
          struts = { left = 0; right = 0; top = 0; bottom = 0; };
          border = { width = 5; active-color = "#33ccffee"; inactive-color = "#595959aa"; };
          default-column-width = { proportion = 0.5; };
        };
        _children = [
          {
            window-rule._children = [
              { match._props = { app-id = "^foot$"; }; }
              { opacity = 0.7; }
            ];
          }
          {
            window-rule._children = [
              { match._props = { app-id = "^orca(-ide)?$"; }; }
              { opacity = 0.7; }
            ];
          }
        ];
        binds = {
          "Mod+O" = { spawn = [ "wlr-which-key" "apps" ]; };
          "Mod+Shift+Z" = { spawn = [ "wlr-which-key" "power" ]; };
          "Mod+Return" = { spawn = [ "foot" ]; };
          "Mod+Semicolon" = { spawn = [ (toString openWindowInColumn) (lib.getExe pkgs.foot) ]; };
          "Mod+D" = { spawn = [ noctalia "msg" "panel-toggle" "launcher" ]; };
          "Mod+X" = { spawn = [ noctalia "msg" "panel-toggle" "clipboard" ]; };
          "Super+Alt+L" = { spawn = [ noctalia "msg" "session" "lock" ]; };
          "Mod+W" = { spawn = [ (toString focusOrLaunchOrca) ]; };
          "Mod+V" = { toggle-overview = {}; };
          "Mod+T" = { toggle-column-tabbed-display = {}; };
          "Mod+C" = { center-column = {}; };
          "Mod+Ctrl+C" = { center-visible-columns = {}; };
          "Mod+F" = { maximize-column = {}; };
          "Mod+Shift+F" = { fullscreen-window = {}; };
          "Mod+N" = { focus-monitor-left = {}; };
          "Mod+M" = { focus-monitor-right = {}; };
          "Mod+Shift+N" = { move-window-to-monitor-left = {}; };
          "Mod+Shift+M" = { move-window-to-monitor-right = {}; };
          "Mod+B" = { toggle-window-floating = {}; };
          "Mod+Shift+B" = { switch-focus-between-floating-and-tiling = {}; };
          "Mod+Q" = { close-window = {}; };
          "Mod+H" = { focus-column-left = {}; };
          "Mod+J" = { focus-window-down = {}; };
          "Mod+K" = { focus-window-up = {}; };
          "Mod+L" = { focus-column-right = {}; };
          "Mod+Left" = { focus-column-left = {}; };
          "Mod+Right" = { focus-column-right = {}; };
          "Mod+Up" = { focus-window-up = {}; };
          "Mod+Down" = { focus-window-down = {}; };
          "Mod+U" = { focus-workspace-down = {}; };
          "Mod+I" = { focus-workspace-up = {}; };
          "Mod+1" = { focus-workspace = 1; };
          "Mod+2" = { focus-workspace = 2; };
          "Mod+3" = { focus-workspace = 3; };
          "Mod+4" = { focus-workspace = 4; };
          "Mod+5" = { focus-workspace = 5; };
          "Mod+6" = { focus-workspace = 6; };
          "Mod+7" = { focus-workspace = 7; };
          "Mod+8" = { focus-workspace = 8; };
          "Mod+9" = { focus-workspace = 9; };
          "Mod+Shift+1" = { move-column-to-workspace = 1; };
          "Mod+Shift+2" = { move-column-to-workspace = 2; };
          "Mod+Shift+3" = { move-column-to-workspace = 3; };
          "Mod+Shift+4" = { move-column-to-workspace = 4; };
          "Mod+Shift+5" = { move-column-to-workspace = 5; };
          "Mod+Shift+6" = { move-column-to-workspace = 6; };
          "Mod+Shift+7" = { move-column-to-workspace = 7; };
          "Mod+Shift+8" = { move-column-to-workspace = 8; };
          "Mod+Shift+9" = { move-column-to-workspace = 9; };
          "Mod+Shift+Slash" = { show-hotkey-overlay = {}; };
          "Mod+Escape" = { toggle-keyboard-shortcuts-inhibit = {}; };
          "Mod+Shift+E" = { quit = {}; };
          "Ctrl+Alt+Delete" = { quit = {}; };
          "Print" = { spawn = [ "sh" "-c" (screenshot "grim") ]; };
          "Ctrl+Print" = { spawn = [ "sh" "-c" (screenshot "grim -g \"$(slurp)\"") ]; };
          "Mod+Shift+P" = { power-off-monitors = {}; };
        };
      } // outputSettings;
    };

    xdg.configFile."wlr-which-key/apps.yaml".text = ''
      font: sans 16
      background: "#202020ee"
      color: "#eeeeee"
      border: "#33ccffee"
      border_width: 2
      anchor: center
      menu:
        - { key: i, desc: KeePassXC, cmd: keepassxc }
        - { key: f, desc: Firefox, cmd: firefox }
        - { key: c, desc: Chrome, cmd: google-chrome-stable }
        - { key: d, desc: Nemo, cmd: nemo }
        - { key: s, desc: Screenshot, cmd: ${noctalia} msg screenshot-region }
        - { key: m, desc: Music, cmd: gtk-launch feishin.desktop }
        - { key: n, desc: Dismiss notifications, cmd: makoctl dismiss --all }
        - { key: h, desc: Notification history, cmd: ${noctalia} msg panel-toggle control-center notifications }
        - { key: g, desc: GoldenDict, cmd: goldendict }
    '';

    xdg.configFile."wlr-which-key/power.yaml".text = ''
      font: sans 16
      background: "#202020ee"
      color: "#eeeeee"
      border: "#33ccffee"
      border_width: 2
      anchor: center
      menu:
        - { key: l, desc: Lock, cmd: ${noctalia} msg session lock }
        - { key: s, desc: Suspend, cmd: systemctl suspend }
        - { key: r, desc: Reboot, cmd: systemctl reboot }
        - { key: p, desc: Shutdown, cmd: systemctl poweroff }
    '';
  };
}
