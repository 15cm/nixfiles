{ config, pkgs, lib, ... }:

with lib;
let cfg = config.my.programs.networkmanager-dmenu;
in {
  options.my.programs.networkmanager-dmenu = {
    enable = mkEnableOption "networkmanager-dmenu";
    package = mkOption {
      type = types.package;
      default = pkgs.networkmanager_dmenu;
      defaultText = literalExpression "pkgs.networkmanager_dmenu";
    };
    settings = mkOption {
      type = types.attrs;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."networkmanager-dmenu/config.ini".text =
      generators.toINI { } cfg.settings;
  };
}
