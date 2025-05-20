{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.services.nix-home-manager-gc;
in {
  options.my.services.nix-home-manager-gc = {
    enable = mkEnableOption "Nix home manager garbage collection";
    args = mkOption {
      type = types.str;
      default = "-7 days";
    };
    persistent = mkOption {
      type = types.bool;
      default = true;
    };
    onCalendar = mkOption {
      type = types.str;
      default = "weekly";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.nix-home-manager-gc = {
      Unit = { Description = "Nix home manager garbage collection"; };
      Service = {
        Type = "oneshot";
        ExecStart =
          "${pkgs.home-manager}/bin/home-manager expire-generations '${cfg.args}'";
        ExecStartPost = "/run/current-system/sw/bin/nix-collect-garbage -d";
      };
    };
    systemd.user.timers.nix-home-manager-gc = {
      Unit = { Description = "Nix home manager garbage collection timer"; };
      Timer = {
        Unit = "nix-home-manager-gc.service";
        OnCalendar = cfg.onCalendar;
        Persistent = cfg.persistent;
      };
      Install = { WantedBy = [ "timers.target" ]; };
    };
  };
}
