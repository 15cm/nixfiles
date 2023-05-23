{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.services.gtklock;
in {
  options.my.services.gtklock = {
    enable = mkEnableOption "gtklock";
    package = mkOption {
      type = types.package;
      default = pkgs.gtklock;
      defaultText = literalExpression "pkgs.gtklock";
      description = "The gtklock package to install.";
    };
    image = mkOption {
      type = with types; nullOr str;
      default = null;
    };
    extraArgs = mkOption {
      type = with types; listOf str;
      default = [ ];
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];
      systemd.user.services.gtklock = {
        Unit = { Description = "Gtklock"; };
        Service = {
          ExecStart = concatStringsSep " " [
            "${cfg.package}/bin/gtklock"
            (escapeShellArgs
              ([ "-g" config.gtk.iconTheme.name ] ++ cfg.extraArgs))
          ];
          Type = "simple";
        };
      };
    }
    (mkIf (cfg.image != null) {
      my.services.gtklock.extraArgs = [ "-b" cfg.image ];
    })
  ]);
}
