# A fork of https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/backup/zrepl.nix that allows passing in a config file directly.

{ config, pkgs, lib, ... }:

with lib;
let cfg = config.services.my-zrepl;
in {
  options = {
    services.my-zrepl = {
      enable = mkEnableOption (lib.mdDoc "zrepl");

      package = mkOption {
        type = types.package;
        default = pkgs.zrepl;
        defaultText = literalExpression "pkgs.zrepl";
        description = lib.mdDoc "Which package to use for zrepl";
      };

      configPath = mkOption {
        default = null;
        description = lib.mdDoc ''
          Path to the configuration for zrepl. See <https://zrepl.github.io/configuration.html>
          for more information.
        '';
        type = with types; nullOr path;
      };
    };
  };

  ### Implementation ###

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    # zrepl looks for its config in this location by default. This
    # allows the use of e.g. `zrepl signal wakeup <job>` without having
    # to specify the storepath of the config.
    environment.etc."zrepl/zrepl.yml".source =
      (assert cfg.configPath != null; cfg.configPath);

    systemd.packages = [ cfg.package ];

    # Note that pkgs.zrepl copies and adapts the upstream systemd unit, and
    # the fields defined here only override certain fields from that unit.
    systemd.services.zrepl = {
      requires = [ "local-fs.target" ];
      wantedBy = [ "zfs.target" ];
      after = [ "zfs.target" ];

      path = [ config.boot.zfs.package ];
      restartTriggers = [ cfg.configPath ];

      serviceConfig = { Restart = "on-failure"; };
    };
  };
}
