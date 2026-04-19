{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.services.syncthing;
    syncthingInitCompat = pkgs.writeShellScript "syncthing-init-compat" ''
      set -eu

      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/syncthing"
      config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/syncthing"

      if [ ! -e "$state_dir/config.xml" ] && [ -e "$config_dir/config.xml" ]; then
        mkdir -p "$state_dir"
        ln -sfn "$config_dir/config.xml" "$state_dir/config.xml"
      fi
    '';
in {
  options.my.services.syncthing = { enable = mkEnableOption "Syncthing"; };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      extraOptions = [ "--allow-newer-config" ];
      tray = {
        enable = true;
        command = "syncthingtray --wait";
      };
    };
    systemd.user.services.syncthingtray = {
      Unit = {
        Requires = mkForce [ ];
        PartOf = mkForce [ "tray.target" ];
        After = mkForce [ "tray.target" ];
      };
      Install.WantedBy = mkForce [ "tray.target" ];
    };
    xdg.configFile."systemd/user/syncthing-init.service.d/compat-config-path.conf".text = ''
      [Service]
      ExecStartPre=${syncthingInitCompat}
    '';
  };
}
