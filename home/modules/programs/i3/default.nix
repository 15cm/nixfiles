{ config, mylib, hostname, state, pkgs, lib, ... }:

with lib;
let
  cfg = config.my.xsession.i3;
  inherit (mylib) templateFile templateShellScriptFile writeShellScriptFile;
  templateData = rec {
    inherit hostname;
    inherit (state) theme;
    inherit (cfg) musicPlayer;
    colorScheme = (if theme == "light" then "solarized-light" else "nord-dark");
    monitors = cfg.monitors;
    i3statusRustBinary = "${pkgs.i3status-rust}/bin/i3status-rs";
  };
in {
  options.my.xsession.i3 = {
    enable = mkEnableOption "i3";
    musicPlayer = mkOption {
      type = types.str;
      default = "clementine";
    };
    monitors = mkOption {
      type = with types; attrsOf str;
      default = {
        one = "DP-0";
        two = "DP-2";
      };
    };
  };

  config = mkIf cfg.enable {
    xsession.windowManager.i3 = {
      enable = true;
      config = null;
      extraConfig = pipe ./config.jinja [
        (templateFile "i3-config" templateData)
        builtins.readFile
      ];
    };

    # i3 Scripts
    xdg.configFile."i3/scripts/i3exit.sh".source =
      writeShellScriptFile "i3-scripts-i3exit.sh" ./scripts/i3exit.sh;

    # Other i3 related packages.
    home.packages = [ pkgs.i3status-rust pkgs.i3-quickterm ];
    xdg.configFile."i3status-rust/config.toml".source =
      templateFile "i3status-rust" templateData ./status.toml.jinja;
    xdg.configFile."i3/i3-quickterm.json".source = ./i3-quickterm.json;
  };
}
