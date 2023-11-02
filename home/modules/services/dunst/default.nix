{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.services.dunst;
in {
  options.my.services.dunst = { enable = mkEnableOption "dunst"; };

  config = mkIf cfg.enable {
    services.dunst = {
      enable = true;
      settings = {
        global = {
          mouse_left_click = "do_action,close_current";
          mouse_middle_click = "close_current";
          mouse_right_click = "context";
        };
      };
    };
  };
}
