{ config, mylib, pkgs, lib, ... }:

with lib;
let
  cfg = config.my.programs.hyprland;
  inherit (mylib) templateFile templateShellScriptFile writeShellScriptFile;
  templateData = {
    inherit (cfg) musicPlayer monitors scale;
    musicPlayerLower = toLower cfg.musicPlayer;
    windowSwitcherScript = "python " + ./window_switcher.py;
  };
in {
  options.my.programs.hyprland = {
    enable = mkEnableOption "hyprland";
    musicPlayer = mkOption {
      type = types.str;
      default = "Feishin";
    };
    monitors = mkOption {
      type = types.attrs;
      default = { };
    };
    scale = mkOption {
      type = types.float;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      enableNvidiaPatches = true;
      xwayland = { enable = true; };
      # Write my own systemd integration to import all needed variables into systemd first.
      systemdIntegration = false;
      extraConfig = let
        sessionImportVariables =
          (builtins.attrNames config.home.sessionVariables) ++ [
            "SSH_AGENT_PID"
            "SSH_AUTH_SOCK"
            "WAYLAND_DISPLAY"
            "HYPRLAND_INSTANCE_SIGNATURE"
            "XDG_CURRENT_DESKTOP"
          ];
        sessionInitCommand =
          "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd ${
            escapeShellArgs sessionImportVariables
          } && systemctl --user import-environment ${
            escapeShellArgs sessionImportVariables
          } && systemctl --user start hyprland-session.target";
      in ''
        exec-once = ${sessionInitCommand}
        exec-once = hyprctl setcursor breeze_cursors ${
          builtins.toString config.my.display.cursorSize
        }
      '' + (pipe ./hyprland.conf.jinja [
        (templateFile "hyprland.conf" templateData)
        builtins.readFile
      ]);
    };
    systemd.user = {
      targets = {
        hyprland-session = {
          Unit = {
            Description = "hyprland compositor session";
            Documentation = [ "man:systemd.special(7)" ];
            BindsTo = [ "graphical-session.target" ];
            Wants = [ "graphical-session-pre.target" ];
            After = [ "graphical-session-pre.target" ];
          };
        };
      };
    };
  };
}
