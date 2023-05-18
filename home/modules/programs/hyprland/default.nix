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
      systemdIntegration = true;
      extraConfig = pipe ./hyprland.conf.jinja [
        (templateFile "hyprland.conf" templateData)
        builtins.readFile
      ];
    };
  };
}
