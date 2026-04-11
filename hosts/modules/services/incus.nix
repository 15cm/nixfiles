{ config, lib, pkgs, ... }:

with lib;

let cfg = config.my.services.incus;
in {
  options.my.services.incus = {
    enable = mkEnableOption "incus";

    softDaemonRestart = mkOption {
      type = types.bool;
      default = true;
      description = "Restart the daemon without interrupting running instances on config change.";
    };

    ui.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the Incus web UI.";
    };
  };

  config = mkIf cfg.enable {
    # Incus on NixOS requires the nftables backend.
    networking.nftables.enable = mkDefault true;

    virtualisation.incus = {
      enable = true;
      package = pkgs.incus;
      softDaemonRestart = cfg.softDaemonRestart;
      ui.enable = cfg.ui.enable;
    };

    users.users.sinkerine.extraGroups = [ "incus-admin" ];
  };
}
