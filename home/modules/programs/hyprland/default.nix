{ config, mylib, hostname, state, pkgs, lib, ... }:

with lib;
let
  cfg = config.my.programs.hyprland;
  inherit (mylib) templateFile templateShellScriptFile writeShellScriptFile;
  templateData = rec {
    inherit (cfg) musicPlayer monitors;
    enableNightLightShader = (cfg.nightLightTemperature != null);
  } // optionalAttrs (cfg.nightLightTemperature != null) {
    nightLightShaderPath = templateFile "hyprland-shader.gsls" {
      temperature = cfg.nightLightTemperature;
    } ./night-light-shader.glsl.jinja;
  };
in {
  options.my.programs.hyprland = {
    enable = mkEnableOption "hyprland";
    musicPlayer = mkOption {
      type = types.str;
      default = "clementine";
    };
    monitors = mkOption {
      type = with types; attrsOf str;
      default = { };
    };
    # Work around of https://github.com/NVIDIA/open-gpu-kernel-modules/issues/162 before nvidia supports GAMMA_LUT for gammastep to work.
    nightLightTemperature = mkOption {
      type = with types; nullOr int;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      nvidiaPatches = true;
      xwayland = {
        enable = true;
        hidpi = true;
      };
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
        exec-once = hyprctl setcursor Vanilla-DMZ 24
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
            BindsTo = [ "graphical-session.target" "tray.target" ];
            Wants = [ "graphical-session-pre.target" ];
            After = [ "graphical-session-pre.target" ];
          };
        };
        tray = {
          Unit = {
            Description = "Home Manager System Tray";
            Requires = [ "graphical-session-pre.target" ];
          };
        };
      };
    };
  };
}
